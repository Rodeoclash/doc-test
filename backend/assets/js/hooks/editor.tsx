import { Hook, makeHook } from 'phoenix_typed_hook';
import { createRoot, type Root } from 'react-dom/client';
import Editor from './editor/Editor';

class EditorHook extends Hook {
  root: Root | null = null;

  mounted() {
    this.root = createRoot(this.el);
    this.root.render(<Editor />);
  }

  destroyed() {
    this.root?.unmount();
    this.root = null;
  }
}

export default makeHook(EditorHook);
