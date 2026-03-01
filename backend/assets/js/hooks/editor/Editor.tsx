import type { InitialConfigType } from '@lexical/react/LexicalComposer';
import type { Channel } from 'phoenix';

import { LexicalComposer } from '@lexical/react/LexicalComposer';
import { RichTextPlugin } from '@lexical/react/LexicalRichTextPlugin';
import { ContentEditable } from '@lexical/react/LexicalContentEditable';
import { LexicalErrorBoundary } from '@lexical/react/LexicalErrorBoundary';
import { AutoFocusPlugin } from '@lexical/react/LexicalAutoFocusPlugin';
import { CollaborationPlugin } from '@lexical/react/LexicalCollaborationPlugin';
import { LexicalCollaboration } from '@lexical/react/LexicalCollaborationContext';
import * as Y from 'yjs';
import { ChangeDeleteNode } from './nodes/change_delete';
import { ChangeInsertNode } from './nodes/change_insert';
import { ChangePopoverPlugin } from './plugins/ChangePopoverPlugin';
import { PhoenixChannelProvider } from '../../user_socket/PhoenixChannelProvider';

const theme = {
  // Theme styling goes here
};

function onError(error: Error): void {
  console.error(error);
}

type EditorProps = {
  channel: Channel;
  documentId: string;
};

export default function Editor({ channel, documentId }: EditorProps) {
  const initialConfig: InitialConfigType = {
    // No editorState — CollaborationPlugin manages state via Yjs
    editorState: null,
    namespace: 'MyEditor',
    nodes: [ChangeDeleteNode, ChangeInsertNode],
    theme,
    onError,
  };

  return (
    <LexicalComposer initialConfig={initialConfig}>
      <LexicalCollaboration>
        <RichTextPlugin
          contentEditable={
            <ContentEditable
              aria-placeholder={'Enter some text...'}
              placeholder={<div>Enter some text...</div>}
            />
          }
          ErrorBoundary={LexicalErrorBoundary}
        />
        <CollaborationPlugin
          id={documentId}
          providerFactory={(id, yjsDocMap) => {
            const doc = new Y.Doc();
            yjsDocMap.set(id, doc);
            return new PhoenixChannelProvider(channel, doc);
          }}
          shouldBootstrap={false}
          username="User"
          cursorColor="#0ea5e9"
        />
        <AutoFocusPlugin />
        <ChangePopoverPlugin />
      </LexicalCollaboration>
    </LexicalComposer>
  );
}
