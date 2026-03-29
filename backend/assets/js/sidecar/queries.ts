import type { LexicalEditor, SerializedEditorState } from "lexical";

const queries: Record<
  string,
  (editor: LexicalEditor) => SerializedEditorState
> = {
  read_document(editor) {
    return editor.getEditorState().toJSON();
  },
};

export default queries;
