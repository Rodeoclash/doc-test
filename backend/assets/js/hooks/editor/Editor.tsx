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
  RichText,
  strikethroughExtension,
  underlineExtension,
  useBaseEditor,
} from "@lexkit/editor";
import type { Channel } from "phoenix";
import * as Y from "yjs";
import { PhoenixChannelProvider } from "../../user_socket/PhoenixChannelProvider";
import { ChangeNode } from "./nodes/change";
import { ChangePopoverPlugin } from "./plugins/ChangePopoverPlugin";

// Register our custom ChangeNode with LexKit's extension system
// so it's included in the editor's node config
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
  changeNodeExtension,
] as const;

type EditorProps = {
  channel: Channel;
  username: string;
};

function ToolbarButton({
  active,
  onClick,
  children,
  title,
}: {
  active?: boolean;
  onClick: () => void;
  children: React.ReactNode;
  title: string;
}) {
  return (
    <button
      type="button"
      title={title}
      onClick={onClick}
      className={[
        "px-2 py-1 rounded text-xs font-medium cursor-pointer",
        active
          ? "bg-blue-100 text-blue-700"
          : "text-gray-500 hover:bg-gray-100 hover:text-gray-700",
      ].join(" ")}
    >
      {children}
    </button>
  );
}

function Divider() {
  return <div className="w-px h-6 bg-gray-200 mx-1" />;
}

function Toolbar() {
  const { commands, activeStates } = useBaseEditor();

  return (
    <div className="bg-white border border-gray-200 rounded-t-lg sticky top-0 z-10 px-2 py-1.5 flex items-center gap-0.5">
      <ToolbarButton
        title="Bold"
        active={activeStates.isBold}
        onClick={() => commands.toggleBold()}
      >
        B
      </ToolbarButton>
      <ToolbarButton
        title="Italic"
        active={activeStates.isItalic}
        onClick={() => commands.toggleItalic()}
      >
        I
      </ToolbarButton>
      <ToolbarButton
        title="Underline"
        active={activeStates.isUnderline}
        onClick={() => commands.toggleUnderline()}
      >
        U
      </ToolbarButton>
      <ToolbarButton
        title="Strikethrough"
        active={activeStates.isStrikethrough}
        onClick={() => commands.toggleStrikethrough()}
      >
        S
      </ToolbarButton>

      <Divider />

      <ToolbarButton
        title="Heading 1"
        active={activeStates.isH1}
        onClick={() => commands.toggleHeading("h1")}
      >
        H1
      </ToolbarButton>
      <ToolbarButton
        title="Heading 2"
        active={activeStates.isH2}
        onClick={() => commands.toggleHeading("h2")}
      >
        H2
      </ToolbarButton>
      <ToolbarButton
        title="Heading 3"
        active={activeStates.isH3}
        onClick={() => commands.toggleHeading("h3")}
      >
        H3
      </ToolbarButton>

      <Divider />

      <ToolbarButton
        title="Bullet list"
        active={activeStates.unorderedList}
        onClick={() => commands.toggleUnorderedList()}
      >
        UL
      </ToolbarButton>
      <ToolbarButton
        title="Numbered list"
        active={activeStates.orderedList}
        onClick={() => commands.toggleOrderedList()}
      >
        OL
      </ToolbarButton>
    </div>
  );
}

export default function Editor({ channel, username }: EditorProps) {
  return (
    <BaseProvider
      extensions={extensions}
      config={{
        theme: defaultLexKitTheme,
      }}
    >
      <LexicalCollaboration>
        <Toolbar />
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
