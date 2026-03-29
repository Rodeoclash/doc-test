import { syncLexicalUpdateToYjs } from "@lexical/yjs";
import type { SerializedEditorState } from "lexical";
import * as Y from "yjs";
import commands from "./sidecar/commands";
import { loadEditor } from "./sidecar/editor";
import { uint8ArrayToBase64 } from "./sidecar/encoding";
import queries from "./sidecar/queries";

// --- Types ---

interface CommandRequest {
  command: string;
  state: string;
  data: SerializedEditorState;
}

type CommandResponse =
  | { ok: true; type: "command"; update: string; data: SerializedEditorState }
  | { ok: true; type: "query"; data: SerializedEditorState }
  | { ok: false; error: string };

// --- Request routing ---

function processCommand(request: CommandRequest): CommandResponse {
  const { command, state: stateBase64, data } = request;

  const queryHandler = queries[command];
  if (queryHandler) {
    const { editor, editorErrors } = loadEditor(stateBase64);
    if (editorErrors.length > 0) {
      return {
        ok: false,
        error: editorErrors.map((e) => e.message).join("; "),
      };
    }
    const result = queryHandler(editor);
    return { ok: true, type: "query", data: result };
  }

  const commandHandler = commands[command];
  if (commandHandler) {
    const { editor, doc, binding, provider, editorErrors } =
      loadEditor(stateBase64);

    // Capture Yjs updates produced by the edit
    const updates: Uint8Array[] = [];
    doc.on("update", (update: Uint8Array) => {
      updates.push(update);
    });

    // Wire Lexical -> Yjs sync
    const removeUpdateListener = editor.registerUpdateListener(
      ({
        prevEditorState,
        editorState,
        dirtyElements,
        dirtyLeaves,
        normalizedNodes,
        tags,
      }) => {
        if (tags.has("collaboration") || tags.has("historic")) {
          return;
        }
        syncLexicalUpdateToYjs(
          binding,
          provider,
          prevEditorState,
          editorState,
          dirtyElements,
          dirtyLeaves,
          normalizedNodes,
          tags,
        );
      },
    );

    // Execute the edit
    try {
      commandHandler(editor, data);
    } catch (e) {
      // Combine async errors (from onError) with the thrown error.
      // The onError errors are typically more specific (e.g. "type X not found")
      // while the thrown error is a downstream consequence (e.g. "state is empty").
      const messages = editorErrors.map((err) => err.message);
      if (e instanceof Error) messages.push(e.message);
      return { ok: false, error: messages.join("; ") };
    }

    if (editorErrors.length > 0) {
      return {
        ok: false,
        error: editorErrors.map((e) => e.message).join("; "),
      };
    }

    // Clean up
    removeUpdateListener();

    if (updates.length === 0) {
      return { ok: false, error: "no updates produced" };
    }

    const merged = Y.mergeUpdates(updates);
    const result = editor.getEditorState().toJSON();
    return {
      ok: true,
      type: "command",
      update: uint8ArrayToBase64(merged),
      data: result,
    };
  }

  return { ok: false, error: `unknown command: ${command}` };
}

// --- stdin/stdout framing ({:packet, 4}) ---

let buffer = Buffer.alloc(0);

process.stdin.resume();
process.stdin.on("data", (chunk: Buffer) => {
  buffer = Buffer.concat([buffer, chunk]);

  while (buffer.length >= 4) {
    const len = buffer.readUInt32BE(0);
    if (buffer.length < 4 + len) break;

    const payload = buffer.subarray(4, 4 + len);
    buffer = buffer.subarray(4 + len);

    let response: CommandResponse;
    try {
      const request: CommandRequest = JSON.parse(payload.toString("utf-8"));
      response = processCommand(request);
    } catch (error) {
      response = {
        ok: false,
        error: error instanceof Error ? error.message : String(error),
      };
    }

    const responseBytes = Buffer.from(JSON.stringify(response), "utf-8");
    const header = Buffer.alloc(4);
    header.writeUInt32BE(responseBytes.length, 0);
    process.stdout.write(Buffer.concat([header, responseBytes]));
  }
});

// Exit cleanly when stdin closes (Elixir process died)
process.stdin.on("end", () => {
  process.exit(0);
});

process.stdin.on("error", () => {
  process.exit(1);
});
