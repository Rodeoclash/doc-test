import { AutoFocusPlugin } from "@lexical/react/LexicalAutoFocusPlugin";
import { LexicalCollaboration } from "@lexical/react/LexicalCollaborationContext";
import { CollaborationPlugin } from "@lexical/react/LexicalCollaborationPlugin";
import type { InitialConfigType } from "@lexical/react/LexicalComposer";
import { LexicalComposer } from "@lexical/react/LexicalComposer";
import { ContentEditable } from "@lexical/react/LexicalContentEditable";
import { LexicalErrorBoundary } from "@lexical/react/LexicalErrorBoundary";
import { ListPlugin } from "@lexical/react/LexicalListPlugin";
import { RichTextPlugin } from "@lexical/react/LexicalRichTextPlugin";
import { TabIndentationPlugin } from "@lexical/react/LexicalTabIndentationPlugin";
import type { Channel } from "phoenix";
import * as Y from "yjs";
import { editorNodes } from "../../editor_nodes";
import { PhoenixChannelProvider } from "../../user_socket/PhoenixChannelProvider";
import { ChangePopoverPlugin } from "./plugins/ChangePopoverPlugin";
import { ToolbarPlugin } from "./plugins/ToolbarPlugin";

function onError(error: Error): void {
  console.error(error);
}

type EditorProps = {
  channel: Channel;
  username: string;
};

export default function Editor({ channel, username }: EditorProps) {
  const initialConfig: InitialConfigType = {
    // No editorState — CollaborationPlugin manages state via Yjs
    editorState: null,
    namespace: "MyEditor",
    nodes: editorNodes,
    onError,
  };

  return (
    <LexicalComposer initialConfig={initialConfig}>
      <LexicalCollaboration>
        <div className="bg-white border border-gray-200 rounded-t-lg sticky top-0 z-10">
          <ToolbarPlugin />
        </div>
        <div className="bg-white border-x border-b border-gray-200 rounded-b-lg p-8 prose prose-sm max-w-none">
          <RichTextPlugin
            contentEditable={<ContentEditable />}
            ErrorBoundary={LexicalErrorBoundary}
          />
        </div>
        <CollaborationPlugin
          id="root"
          providerFactory={(id, yjsDocMap) => {
            const doc = new Y.Doc();
            yjsDocMap.set(id, doc);
            return new PhoenixChannelProvider(channel, doc);
          }}
          shouldBootstrap={false}
          username={username}
          cursorColor="#0ea5e9"
        />
        <ListPlugin />
        <TabIndentationPlugin />
        <AutoFocusPlugin />
        <ChangePopoverPlugin />
      </LexicalCollaboration>
    </LexicalComposer>
  );
}
