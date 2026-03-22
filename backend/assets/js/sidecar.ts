import { createHeadlessEditor } from "@lexical/headless";
import {
  createBinding,
  syncLexicalUpdateToYjs,
  syncYjsChangesToLexical,
} from "@lexical/yjs";
import { type LexicalEditor, type SerializedEditorState } from "lexical";
import * as Y from "yjs";
import { editorNodes } from "./editor_nodes";

// --- No-op provider (satisfies the binding interface without network) ---

function createNoopProvider() {
  return {
    awareness: {
      getLocalState: () => null,
      getStates: () => new Map(),
      setLocalState: () => {},
      setLocalStateField: () => {},
      on: () => {},
      off: () => {},
    },
    connect: () => {},
    disconnect: () => {},
    on: () => {},
    off: () => {},
  };
}

// --- Headless editor with Yjs binding ---

function loadEditor(stateBase64: string) {
  const stateBytes = base64ToUint8Array(stateBase64);

  const doc = new Y.Doc();

  const editor = createHeadlessEditor({
    namespace: "sidecar",
    nodes: editorNodes,
    onError: (error: Error) => {
      throw error;
    },
  });

  const docMap = new Map([["root", doc]]);
  const provider = createNoopProvider();
  const binding = createBinding(editor, provider, "root", doc, docMap);

  // Wire Yjs -> Lexical sync via observer (same as CollaborationPlugin)
  binding.root
    .getSharedType()
    .observeDeep(
      (events: Y.YEvent<Y.XmlText>[], transaction: Y.Transaction) => {
        if (transaction.origin !== binding) {
          syncYjsChangesToLexical(binding, provider, events, false);
        }
      },
    );

  // Apply the Yjs state — triggers the observer which syncs to Lexical
  Y.applyUpdate(doc, stateBytes);

  // Finalise the Lexical editor state
  editor.update(() => {}, { discrete: true });

  return { editor, doc, binding, provider };
}

// --- Command handlers (mutate the document, return Yjs update + data) ---

const commands: Record<
  string,
  (editor: LexicalEditor, data: SerializedEditorState) => void
> = {
  apply_document(editor, data) {
    const newState = editor.parseEditorState(data);
    editor.setEditorState(newState);
  },
};

// --- Query handlers (read-only, return data) ---

const queries: Record<string, (editor: LexicalEditor) => SerializedEditorState> = {
  read_document(editor) {
    return editor.getEditorState().toJSON();
  },
};

// --- Core pipeline ---

interface CommandRequest {
  command: string;
  state: string;
  data: SerializedEditorState;
}

type CommandResponse =
  | { ok: true; type: "command"; update: string; data: SerializedEditorState }
  | { ok: true; type: "query"; data: SerializedEditorState }
  | { ok: false; error: string };

function processCommand(request: CommandRequest): CommandResponse {
  const { command, state: stateBase64, data } = request;

  const queryHandler = queries[command];
  if (queryHandler) {
    const { editor } = loadEditor(stateBase64);
    const result = queryHandler(editor);
    return { ok: true, type: "query", data: result };
  }

  const commandHandler = commands[command];
  if (commandHandler) {
    const { editor, doc, binding, provider } = loadEditor(stateBase64);

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
    commandHandler(editor, data);

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

// --- Base64 helpers ---

function uint8ArrayToBase64(bytes: Uint8Array): string {
  let binary = "";
  for (let i = 0; i < bytes.byteLength; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary);
}

function base64ToUint8Array(base64: string): Uint8Array {
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes;
}
