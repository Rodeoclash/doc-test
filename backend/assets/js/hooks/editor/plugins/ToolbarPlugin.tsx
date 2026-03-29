import {
  INSERT_ORDERED_LIST_COMMAND,
  INSERT_UNORDERED_LIST_COMMAND,
} from "@lexical/list";
import { useLexicalComposerContext } from "@lexical/react/LexicalComposerContext";
import {
  $createHeadingNode,
  $isHeadingNode,
  type HeadingTagType,
} from "@lexical/rich-text";
import { $setBlocksType } from "@lexical/selection";
import {
  $createParagraphNode,
  $getSelection,
  $isRangeSelection,
  FORMAT_TEXT_COMMAND,
  type TextFormatType,
} from "lexical";
import { useCallback, useEffect, useState } from "react";

type BlockType = "paragraph" | HeadingTagType;

type ToolbarState = {
  bold: boolean;
  italic: boolean;
  blockType: BlockType;
};

const emptyState: ToolbarState = {
  bold: false,
  italic: false,
  blockType: "paragraph",
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

export function ToolbarPlugin() {
  const [editor] = useLexicalComposerContext();
  const [state, setState] = useState<ToolbarState>(emptyState);

  useEffect(() => {
    return editor.registerUpdateListener(({ editorState }) => {
      editorState.read(() => {
        const selection = $getSelection();
        if (!$isRangeSelection(selection)) {
          setState(emptyState);
          return;
        }

        // Detect block type from the anchor node's nearest block parent
        let blockType: BlockType = "paragraph";
        const anchorNode = selection.anchor.getNode();
        const parent = anchorNode.getTopLevelElement();
        if (parent && $isHeadingNode(parent)) {
          blockType = parent.getTag();
        }

        setState({
          bold: selection.hasFormat("bold"),
          italic: selection.hasFormat("italic"),
          blockType,
        });
      });
    });
  }, [editor]);

  const formatText = useCallback(
    (format: TextFormatType) => {
      editor.dispatchCommand(FORMAT_TEXT_COMMAND, format);
    },
    [editor],
  );

  const toggleHeading = useCallback(
    (tag: HeadingTagType) => {
      editor.update(() => {
        const selection = $getSelection();
        if (!$isRangeSelection(selection)) return;

        // Toggle: if already this heading, revert to paragraph
        if (state.blockType === tag) {
          $setBlocksType(selection, () => $createParagraphNode());
        } else {
          $setBlocksType(selection, () => $createHeadingNode(tag));
        }
      });
    },
    [editor, state.blockType],
  );

  return (
    <div className="flex items-center gap-0.5 px-2 py-1.5">
      <ToolbarButton
        title="Bold"
        active={state.bold}
        onClick={() => formatText("bold")}
      >
        <BoldIcon />
      </ToolbarButton>
      <ToolbarButton
        title="Italic"
        active={state.italic}
        onClick={() => formatText("italic")}
      >
        <ItalicIcon />
      </ToolbarButton>

      <Divider />

      <ToolbarButton
        title="Heading 1"
        active={state.blockType === "h1"}
        onClick={() => toggleHeading("h1")}
      >
        <span className="text-xs font-bold">H1</span>
      </ToolbarButton>
      <ToolbarButton
        title="Heading 2"
        active={state.blockType === "h2"}
        onClick={() => toggleHeading("h2")}
      >
        <span className="text-xs font-bold">H2</span>
      </ToolbarButton>
      <ToolbarButton
        title="Heading 3"
        active={state.blockType === "h3"}
        onClick={() => toggleHeading("h3")}
      >
        <span className="text-xs font-bold">H3</span>
      </ToolbarButton>

      <Divider />

      <ToolbarButton
        title="Bullet list"
        onClick={() =>
          editor.dispatchCommand(INSERT_UNORDERED_LIST_COMMAND, undefined)
        }
      >
        <ListBulletIcon />
      </ToolbarButton>
      <ToolbarButton
        title="Numbered list"
        onClick={() =>
          editor.dispatchCommand(INSERT_ORDERED_LIST_COMMAND, undefined)
        }
      >
        <NumberedListIcon />
      </ToolbarButton>
    </div>
  );
}

// Inline SVG icons matching heroicons outline style (24x24 viewBox, 1.5 stroke)
function BoldIcon() {
  return (
    <svg
      aria-hidden="true"
      className="size-5"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={1.5}
    >
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M6.75 4.5h6a3.75 3.75 0 0 1 0 7.5H6.75V4.5Zm0 7.5h7.5a3.75 3.75 0 0 1 0 7.5h-7.5V12Z"
      />
    </svg>
  );
}

function ItalicIcon() {
  return (
    <svg
      aria-hidden="true"
      className="size-5"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={1.5}
    >
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M10 4.5h8M6 19.5h8M14.25 4.5 9.75 19.5"
      />
    </svg>
  );
}

function ListBulletIcon() {
  return (
    <svg
      aria-hidden="true"
      className="size-5"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={1.5}
    >
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M8.25 6.75h11.25M8.25 12h11.25M8.25 17.25h11.25M4.5 6.75h.008v.008H4.5V6.75Zm0 5.25h.008v.008H4.5V12Zm0 5.25h.008v.008H4.5v-.008Z"
      />
    </svg>
  );
}

function NumberedListIcon() {
  return (
    <svg
      aria-hidden="true"
      className="size-5"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={1.5}
    >
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M8.242 5.992h11.425M8.242 12.067h11.425M8.242 18.142h11.425M4.117 5.992V3.867l-1.275.388M4.117 18.142H2.842m1.275 0H2.842m1.275 0V15.867l-1.275.85M4.117 12.067V9.942l-1.275.388"
      />
    </svg>
  );
}
