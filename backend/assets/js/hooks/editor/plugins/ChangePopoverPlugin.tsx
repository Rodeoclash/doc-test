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
import { computePosition, flip, shift, offset, autoUpdate } from '@floating-ui/dom';

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
  const referenceElRef = useRef<HTMLElement | null>(null);

  // On every editor update, check if the cursor is inside a change node.
  // If so, store its changeId and DOM element for popover positioning.
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

        // Get the actual DOM element so Floating UI can anchor the popover to it
        const domElement = editor.getElementByKey(changeNode.getKey());
        
        if (!domElement) {
          setActiveChangeId(null);
          return;
        }

        referenceElRef.current = domElement;
        setActiveChangeId(changeNode.__changeId);
      });
    });
  }, [editor]);

  // Position the popover beneath the change node's DOM element.
  // autoUpdate keeps it anchored on scroll/resize and returns its own cleanup.
  // Starts hidden to avoid a flash at (0,0) before computePosition resolves.
  useEffect(() => {
    const referenceEl = referenceElRef.current;
    const popoverEl = popoverRef.current;
    if (!activeChangeId || !referenceEl || !popoverEl) return;

    popoverEl.style.visibility = 'hidden';

    return autoUpdate(referenceEl, popoverEl, () => {
      computePosition(referenceEl, popoverEl, {
        placement: 'bottom',
        middleware: [offset(4), flip(), shift({ padding: 8 })],
      }).then(({ x, y }) => {
        popoverEl.style.left = `${x}px`;
        popoverEl.style.top = `${y}px`;
        popoverEl.style.visibility = 'visible';
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
