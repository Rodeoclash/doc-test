import {
  $createParagraphNode,
  $createTextNode,
  $getRoot,
  createEditor,
  type LexicalEditor,
  type SerializedEditorState,
} from "lexical";
import {
  createBinding,
  syncLexicalUpdateToYjs,
} from "@lexical/yjs";
import * as Y from "yjs";

import { ChangeInsertNode } from "./hooks/editor/nodes/change_insert";
import { ChangeDeleteNode } from "./hooks/editor/nodes/change_delete";

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

// --- Command handlers (mutate the document, return Yjs update + data) ---

const commands: Record<string, (editor: LexicalEditor) => void> = {
  append_hello(editor) {
    editor.update(
      () => {
        const root = $getRoot();
        const paragraph = $createParagraphNode();
        paragraph.append($createTextNode("hello world"));
        root.append(paragraph);
      },
      { discrete: true },
    );
  },
};

// --- Query handlers (read-only, return data) ---

const queries: Record<string, (editor: LexicalEditor) => unknown> = {
  read_document(editor) {
    return editor.getEditorState().toJSON();
  },
};

// --- Core edit pipeline ---

interface CommandRequest {
  command: string;
  state: string;
}

type CommandResponse =
  | { ok: true; type: "command"; update: string; data: SerializedEditorState }
  | { ok: true; type: "query"; data: SerializedEditorState }
  | { ok: false; error: string };

function loadEditor(stateBase64: string) {
  const stateBytes = base64ToUint8Array(stateBase64);

  // Create Y.Doc and load the current document state
  const doc = new Y.Doc();
  doc.transact(() => {
    Y.applyUpdate(doc, stateBytes);
  }, "load");

  // Create a headless editor (no setRootElement — avoids DOM reconciliation)
  const editor = createEditor({
    namespace: "sidecar",
    nodes: [ChangeInsertNode, ChangeDeleteNode],
    onError: (error: Error) => {
      throw error;
    },
  });

  // Create the v1 binding to link Lexical <-> Y.Doc
  const docMap = new Map([["sidecar", doc]]);
  const provider = createNoopProvider();
  const binding = createBinding(editor, provider, "sidecar", doc, docMap);

  // Sync existing Yjs state into Lexical editor
  editor.update(
    () => {
      const root = binding.root;
      root.syncPropertiesFromYjs(binding, null);
      root.syncChildrenFromYjs(binding, null);
    },
    { tag: "collaboration", discrete: true },
  );

  return { editor, doc, binding, provider };
}

function processCommand(request: CommandRequest): CommandResponse {
  const { command, state: stateBase64 } = request;

  const queryHandler = queries[command];
  if (queryHandler) {
    const { editor } = loadEditor(stateBase64);
    const data = queryHandler(editor);
    return { ok: true, type: "query", data };
  }

  const commandHandler = commands[command];
  if (commandHandler) {
    const { editor, doc, binding, provider } = loadEditor(stateBase64);

    // Capture updates produced by our edit (after initial load)
    const updates: Uint8Array[] = [];
    doc.on("update", (update: Uint8Array) => {
      updates.push(update);
    });

    // Wire Lexical -> Yjs sync via the update listener
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

    // Execute the requested edit
    commandHandler(editor);

    // Clean up
    removeUpdateListener();

    if (updates.length === 0) {
      return { ok: false, error: "no updates produced" };
    }

    const merged = Y.mergeUpdates(updates);
    const data = editor.getEditorState().toJSON();
    return { ok: true, type: "command", update: uint8ArrayToBase64(merged), data };
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
      response = { ok: false, error: (error as Error).message };
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
