import { Hook, makeHook } from 'phoenix_typed_hook';
import { createRoot, type Root } from 'react-dom/client';
import type { Channel } from 'phoenix';
import Editor from './editor/Editor';
import { createDocumentChannel } from '../user_socket/document_channel';

class EditorHook extends Hook {
  root: Root | null = null;
  channel: Channel | null = null;

  mounted() {
    const documentId = this.el.dataset.documentId;
    if (!documentId) {
      console.error('EditorHook: missing data-document-id');
      return;
    }

    this.channel = createDocumentChannel(documentId);
    this.root = createRoot(this.el);
    this.root.render(<Editor channel={this.channel} documentId={documentId} />);
  }

  destroyed() {
    this.root?.unmount();
    this.root = null;
    // Channel leave is handled by the provider's disconnect()
    this.channel = null;
  }
}

export default makeHook(EditorHook);
