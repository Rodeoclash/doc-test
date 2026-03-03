import { AutoFocusPlugin } from "@lexical/react/LexicalAutoFocusPlugin";
import { LexicalCollaboration } from "@lexical/react/LexicalCollaborationContext";
import { CollaborationPlugin } from "@lexical/react/LexicalCollaborationPlugin";
import type { InitialConfigType } from "@lexical/react/LexicalComposer";
import { LexicalComposer } from "@lexical/react/LexicalComposer";
import { ContentEditable } from "@lexical/react/LexicalContentEditable";
import { LexicalErrorBoundary } from "@lexical/react/LexicalErrorBoundary";
import { RichTextPlugin } from "@lexical/react/LexicalRichTextPlugin";
import type { Channel } from "phoenix";
import * as Y from "yjs";
import { PhoenixChannelProvider } from "../../user_socket/PhoenixChannelProvider";
import { ChangeDeleteNode } from "./nodes/change_delete";
import { ChangeInsertNode } from "./nodes/change_insert";
import { ChangePopoverPlugin } from "./plugins/ChangePopoverPlugin";

const theme = {
  // Theme styling goes here
};

function onError(error: Error): void {
  console.error(error);
}

type EditorProps = {
  channel: Channel;
  documentId: string;
  username: string;
};

export default function Editor({ channel, documentId, username }: EditorProps) {
  const initialConfig: InitialConfigType = {
    // No editorState — CollaborationPlugin manages state via Yjs
    editorState: null,
    namespace: "MyEditor",
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
              aria-placeholder={"Enter some text..."}
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
          username={username}
          cursorColor="#0ea5e9"
        />
        <AutoFocusPlugin />
        <ChangePopoverPlugin />
      </LexicalCollaboration>
    </LexicalComposer>
  );
}
