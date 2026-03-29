import { useBaseEditor } from "@lexkit/editor";
import {
  Bold,
  Columns3,
  Heading1,
  Heading2,
  Heading3,
  Italic,
  List,
  ListOrdered,
  Minus,
  Rows3,
  Strikethrough,
  Table,
  Trash2,
  Underline,
} from "lucide-react";

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
        "p-1.5 rounded cursor-pointer",
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

const iconSize = 16;

export function ToolbarPlugin() {
  const { commands, activeStates } = useBaseEditor();

  const inTable = activeStates.isInTableCell;

  return (
    <div className="bg-white border border-gray-200 rounded-t-lg sticky top-0 z-10 px-2 py-1.5 flex items-center gap-0.5 flex-wrap">
      <ToolbarButton
        title="Bold"
        active={activeStates.isBold}
        onClick={() => commands.toggleBold()}
      >
        <Bold size={iconSize} />
      </ToolbarButton>
      <ToolbarButton
        title="Italic"
        active={activeStates.isItalic}
        onClick={() => commands.toggleItalic()}
      >
        <Italic size={iconSize} />
      </ToolbarButton>
      <ToolbarButton
        title="Underline"
        active={activeStates.isUnderline}
        onClick={() => commands.toggleUnderline()}
      >
        <Underline size={iconSize} />
      </ToolbarButton>
      <ToolbarButton
        title="Strikethrough"
        active={activeStates.isStrikethrough}
        onClick={() => commands.toggleStrikethrough()}
      >
        <Strikethrough size={iconSize} />
      </ToolbarButton>

      <Divider />

      <ToolbarButton
        title="Heading 1"
        active={activeStates.isH1}
        onClick={() => commands.toggleHeading("h1")}
      >
        <Heading1 size={iconSize} />
      </ToolbarButton>
      <ToolbarButton
        title="Heading 2"
        active={activeStates.isH2}
        onClick={() => commands.toggleHeading("h2")}
      >
        <Heading2 size={iconSize} />
      </ToolbarButton>
      <ToolbarButton
        title="Heading 3"
        active={activeStates.isH3}
        onClick={() => commands.toggleHeading("h3")}
      >
        <Heading3 size={iconSize} />
      </ToolbarButton>

      <Divider />

      <ToolbarButton
        title="Bullet list"
        active={activeStates.unorderedList}
        onClick={() => commands.toggleUnorderedList()}
      >
        <List size={iconSize} />
      </ToolbarButton>
      <ToolbarButton
        title="Numbered list"
        active={activeStates.orderedList}
        onClick={() => commands.toggleOrderedList()}
      >
        <ListOrdered size={iconSize} />
      </ToolbarButton>

      <Divider />

      <ToolbarButton
        title="Insert table"
        onClick={() =>
          commands.insertTable({ rows: 3, columns: 3, includeHeaders: true })
        }
      >
        <Table size={iconSize} />
      </ToolbarButton>

      {inTable && (
        <>
          <Divider />
          <ToolbarButton
            title="Insert row"
            onClick={() => commands.insertRowBelow()}
          >
            <Rows3 size={iconSize} />
          </ToolbarButton>
          <ToolbarButton
            title="Insert column"
            onClick={() => commands.insertColumnRight()}
          >
            <Columns3 size={iconSize} />
          </ToolbarButton>
          <ToolbarButton
            title="Delete row"
            onClick={() => commands.deleteRow()}
          >
            <Minus size={iconSize} />
          </ToolbarButton>
          <ToolbarButton
            title="Delete table"
            onClick={() => commands.deleteTable()}
          >
            <Trash2 size={iconSize} />
          </ToolbarButton>
        </>
      )}
    </div>
  );
}
