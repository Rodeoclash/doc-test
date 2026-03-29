import { createHeadlessEditor } from "@lexical/headless";
import { createBinding, syncYjsChangesToLexical } from "@lexical/yjs";
import type { LexicalEditor } from "lexical";
import * as Y from "yjs";
import { editorNodes } from "../editor_nodes";
import { base64ToUint8Array } from "./encoding";

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

export interface LoadedEditor {
  editor: LexicalEditor;
  doc: Y.Doc;
  binding: ReturnType<typeof createBinding>;
  provider: ReturnType<typeof createNoopProvider>;
  editorErrors: Error[];
}

export function loadEditor(stateBase64: string): LoadedEditor {
  const stateBytes = base64ToUint8Array(stateBase64);

  const doc = new Y.Doc();

  // Collect errors from Lexical rather than throwing, which would crash
  // the sidecar process. Callers check editorErrors after operations.
  const editorErrors: Error[] = [];
  const editor = createHeadlessEditor({
    namespace: "sidecar",
    nodes: editorNodes,
    onError: (error: Error) => {
      editorErrors.push(error);
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

  return { editor, doc, binding, provider, editorErrors };
}
