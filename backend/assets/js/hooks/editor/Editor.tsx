import { AutoFocusPlugin } from "@lexical/react/LexicalAutoFocusPlugin";
import { LexicalCollaboration } from "@lexical/react/LexicalCollaborationContext";
import { CollaborationPlugin } from "@lexical/react/LexicalCollaborationPlugin";
import { ListPlugin } from "@lexical/react/LexicalListPlugin";
import { TabIndentationPlugin } from "@lexical/react/LexicalTabIndentationPlugin";
import {
  BaseProvider,
  blockFormatExtension,
  boldExtension,
  contextMenuExtension,
  createExtension,
  defaultLexKitTheme,
  draggableBlockExtension,
  historyExtension,
  horizontalRuleExtension,
  italicExtension,
  linkExtension,
  listExtension,
  RichText,
  strikethroughExtension,
  tableExtension,
  underlineExtension,
} from "@lexkit/editor";
import type { Channel } from "phoenix";
import * as Y from "yjs";
import { PhoenixChannelProvider } from "../../user_socket/PhoenixChannelProvider";
import { ChangeNode } from "./nodes/change";
import { ChangePopoverPlugin } from "./plugins/ChangePopoverPlugin";
import { ToolbarPlugin } from "./plugins/ToolbarPlugin";

const changeNodeExtension = createExtension({
  name: "changeNode",
  nodes: [ChangeNode],
});

const extensions = [
  boldExtension,
  italicExtension,
  underlineExtension,
  strikethroughExtension,
  listExtension,
  blockFormatExtension,
  historyExtension,
  linkExtension,
  horizontalRuleExtension,
  draggableBlockExtension.configure({ offsetLeft: -22 }),
  contextMenuExtension,
  tableExtension.configure({
    enableContextMenu: true,
    contextMenuExtension,
  }),
  changeNodeExtension,
] as const;

type EditorProps = {
  channel: Channel;
  username: string;
};

export default function Editor({ channel, username }: EditorProps) {
  return (
    <BaseProvider
      extensions={extensions}
      config={{
        theme: defaultLexKitTheme,
      }}
    >
      <LexicalCollaboration>
        <ToolbarPlugin />
        <div className="bg-white border-x border-b border-gray-200 rounded-b-lg px-8 py-4">
          <RichText />
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
    </BaseProvider>
  );
}
