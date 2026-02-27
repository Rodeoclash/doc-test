import { Hook, makeHook } from 'phoenix_typed_hook';
import { createRoot, type Root } from 'react-dom/client';
import type { Channel } from 'phoenix';
import Editor from './editor/Editor';
import { joinDocumentChannel } from '../user_socket/document_channel';

class EditorHook extends Hook {
  root: Root | null = null;
  channel: Channel | null = null;

  mounted() {
    this.root = createRoot(this.el);
    this.root.render(<Editor />);

    const documentId = this.el.dataset.documentId;
    if (documentId) {
      this.channel = joinDocumentChannel(documentId);
    }
  }

  destroyed() {
    this.channel?.leave();
    this.channel = null;
    this.root?.unmount();
    this.root = null;
  }
}

export default makeHook(EditorHook);
