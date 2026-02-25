import { useEffect, useRef, useState, useCallback } from 'react';
import { createPortal } from 'react-dom';
import { useLexicalComposerContext } from '@lexical/react/LexicalComposerContext';
import {
  $getSelection,
  $isRangeSelection,
  $isElementNode,
  $getRoot,
  type LexicalNode,
  type ElementNode,
} from 'lexical';
import { $isChangeDeleteNode, type ChangeDeleteNode } from '../nodes/change_delete';
import { $isChangeInsertNode, type ChangeInsertNode } from '../nodes/change_insert';
import {
  computePosition,
  flip,
  shift,
  offset,
  arrow,
  autoUpdate,
  type VirtualElement,
} from '@floating-ui/dom';

type ChangeNode = ChangeDeleteNode | ChangeInsertNode;

// Walk up from a node to find the nearest change node ancestor.
// Returns null if the node isn't inside a tracked change.
function $findChangeNode(node: LexicalNode | null): ChangeNode | null {
  let current: LexicalNode | null = node;
  while (current) {
    if ($isChangeDeleteNode(current) || $isChangeInsertNode(current)) {
      return current;
    }
    current = current.getParent();
  }
  return null;
}

// Find the paired delete/insert nodes for a given changeId by walking the tree.
// A tracked change always has a delete and insert node sharing the same changeId.
function $findChangeNodesById(changeId: string): {
  deleteNode: ChangeDeleteNode | null;
  insertNode: ChangeInsertNode | null;
} {
  let deleteNode: ChangeDeleteNode | null = null;
  let insertNode: ChangeInsertNode | null = null;

  function walk(node: LexicalNode): void {
    if ($isChangeDeleteNode(node) && node.__changeId === changeId) {
      deleteNode = node;
    }
    if ($isChangeInsertNode(node) && node.__changeId === changeId) {
      insertNode = node;
    }
    if ($isElementNode(node)) {
      for (const child of node.getChildren()) {
        walk(child);
      }
    }
  }

  walk($getRoot());
  return { deleteNode, insertNode };
}

// Move a change node's children into its parent, then remove the now-empty wrapper.
// e.g. <paragraph> <change-insert> "main" </change-insert> </paragraph>
//   -> <paragraph> "main" </paragraph>
function $unwrapChangeNode(node: ElementNode): void {
  const children = node.getChildren();
  for (const child of children) {
    node.insertBefore(child);
  }
  node.remove();
}

export function ChangePopoverPlugin() {
  const [editor] = useLexicalComposerContext();
  const [activeChangeId, setActiveChangeId] = useState<string | null>(null);
  const popoverRef = useRef<HTMLDivElement>(null);
  const arrowRef = useRef<HTMLDivElement>(null);
  const referenceRef = useRef<VirtualElement | null>(null);

  // On every editor update, check if the cursor is inside a change node.
  // If so, find both the delete and insert nodes for that changeId and build
  // a virtual reference element spanning both so the popover centres on the
  // full change rather than whichever node the cursor happens to be in.
  useEffect(() => {
    return editor.registerUpdateListener(({ editorState }) => {
      editorState.read(() => {
        const selection = $getSelection();
        if (!$isRangeSelection(selection)) {
          setActiveChangeId(null);
          return;
        }

        const anchorNode = selection.anchor.getNode();
        const changeNode = $findChangeNode(anchorNode);

        if (!changeNode) {
          setActiveChangeId(null);
          return;
        }

        const changeId = changeNode.__changeId;
        const { deleteNode, insertNode } = $findChangeNodesById(changeId);

        // Collect DOM elements for both sides of the change
        const elements = [deleteNode, insertNode]
          .map((n) => (n ? editor.getElementByKey(n.getKey()) : null))
          .filter((el): el is HTMLElement => el != null);

        if (elements.length === 0) {
          setActiveChangeId(null);
          return;
        }

        // Virtual element whose bounding rect spans both change nodes
        referenceRef.current = {
          getBoundingClientRect() {
            const rects = elements.map((el) => el.getBoundingClientRect());
            const top = Math.min(...rects.map((r) => r.top));
            const left = Math.min(...rects.map((r) => r.left));
            const bottom = Math.max(...rects.map((r) => r.bottom));
            const right = Math.max(...rects.map((r) => r.right));
            return new DOMRect(left, top, right - left, bottom - top);
          },
        };

        setActiveChangeId(changeId);
      });
    });
  }, [editor]);

  // Position the popover beneath the virtual reference spanning both change nodes.
  // autoUpdate keeps it anchored on scroll/resize and returns its own cleanup.
  // Starts hidden to avoid a flash at (0,0) before computePosition resolves.
  useEffect(() => {
    const reference = referenceRef.current;
    const popoverEl = popoverRef.current;
    const arrowEl = arrowRef.current;
    if (!activeChangeId || !reference || !popoverEl || !arrowEl) return;

    popoverEl.style.visibility = 'hidden';

    return autoUpdate(reference, popoverEl, () => {
      computePosition(reference, popoverEl, {
        placement: 'bottom',
        middleware: [
          offset(8),
          flip(),
          shift({ padding: 8 }),
          arrow({ element: arrowEl }),
        ],
      }).then(({ x, y, placement, middlewareData }) => {
        popoverEl.style.left = `${x}px`;
        popoverEl.style.top = `${y}px`;
        popoverEl.style.visibility = 'visible';

        // Position the arrow on the edge facing the reference.
        // placement may flip (e.g. bottom → top), so we derive which
        // edge the arrow sits on from the actual resolved placement.
        const side = placement.split('-')[0] as 'top' | 'bottom';
        const staticSide = side === 'bottom' ? 'top' : 'bottom';
        const arrowRotation = side === 'bottom' ? 'rotate(45deg)' : 'rotate(225deg)';
        const arrowData = middlewareData.arrow;

        if (arrowData) {
          Object.assign(arrowEl.style, {
            left: arrowData.x != null ? `${arrowData.x}px` : '',
            top: '',
            bottom: '',
            [staticSide]: '-4px',
            transform: arrowRotation,
          });
        }
      });
    });
  }, [activeChangeId]);

  // Accept: unwrap the insert node's children into the paragraph, remove the delete node.
  // Reject: unwrap the delete node's children into the paragraph, remove the insert node.
  const resolveChange = useCallback(
    (keepType: 'insert' | 'delete') => {
      if (!activeChangeId) return;

      editor.update(() => {
        const { deleteNode, insertNode } = $findChangeNodesById(activeChangeId);

        if (keepType === 'insert') {
          if (insertNode) $unwrapChangeNode(insertNode);
          if (deleteNode) deleteNode.remove();
        } else {
          if (deleteNode) $unwrapChangeNode(deleteNode);
          if (insertNode) insertNode.remove();
        }
      });

      setActiveChangeId(null);
    },
    [editor, activeChangeId],
  );

  // No active change = no popover. Portal renders into document.body
  // so it floats above the editor without affecting its layout.
  if (!activeChangeId) return null;

  return createPortal(
    <div
      ref={popoverRef}
      className="fixed z-50 bg-white rounded-lg shadow-lg border border-gray-200 p-1 flex gap-1"
    >
      <div
        ref={arrowRef}
        className="absolute w-2 h-2 bg-white border-l border-t border-gray-200"
      />
      <button
        className="px-2 py-1 text-xs bg-green-100 hover:bg-green-200 text-green-800 rounded cursor-pointer"
        onClick={() => resolveChange('insert')}
      >
        Accept
      </button>
      <button
        className="px-2 py-1 text-xs bg-red-100 hover:bg-red-200 text-red-800 rounded cursor-pointer"
        onClick={() => resolveChange('delete')}
      >
        Reject
      </button>
    </div>,
    document.body,
  );
}
