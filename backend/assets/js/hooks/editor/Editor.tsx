import { AutoFocusPlugin } from "@lexical/react/LexicalAutoFocusPlugin";
import { LexicalCollaboration } from "@lexical/react/LexicalCollaborationContext";
import { CollaborationPlugin } from "@lexical/react/LexicalCollaborationPlugin";
import { ListPlugin } from "@lexical/react/LexicalListPlugin";
import { TabIndentationPlugin } from "@lexical/react/LexicalTabIndentationPlugin";
import {
  BaseProvider,
  blockFormatExtension,
  boldExtension,
  createExtension,
  defaultLexKitTheme,
  historyExtension,
  italicExtension,
  linkExtension,
  listExtension,
  mergeThemes,
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
  tableExtension,
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
        theme: mergeThemes(defaultLexKitTheme, {
          tableCellSelected: "lexkit-table-cell-selected",
          tableSelection: "lexkit-table-selection",
        }),
      }}
    >
      <LexicalCollaboration>
        <ToolbarPlugin />
        <div className="bg-white border-x border-b border-gray-200 rounded-b-lg p-8 prose prose-sm max-w-none">
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
