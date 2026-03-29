import type { LexicalEditor, SerializedEditorState } from "lexical";

const commands: Record<
  string,
  (editor: LexicalEditor, data: SerializedEditorState) => void
> = {
  apply_document(editor, data) {
    const newState = editor.parseEditorState(data);
    if (newState.isEmpty()) {
      throw new Error(
        "parseEditorState failed: produced an empty editor state",
      );
    }
    editor.setEditorState(newState);
  },
};

export default commands;
