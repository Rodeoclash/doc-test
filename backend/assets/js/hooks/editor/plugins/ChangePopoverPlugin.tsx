import { useEffect, useRef } from 'react';
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

function $unwrapChangeNode(node: ElementNode): void {
  const children = node.getChildren();
  for (const child of children) {
    node.insertBefore(child);
  }
  node.remove();
}

export function ChangePopoverPlugin(): null {
  const [editor] = useLexicalComposerContext();
  const popoverRef = useRef<HTMLDivElement | null>(null);
  const cleanupRef = useRef<(() => void) | null>(null);
  const activeChangeIdRef = useRef<string | null>(null);

  useEffect(() => {
    const popover = document.createElement('div');
    popover.className =
      'fixed z-50 bg-white rounded-lg shadow-lg border border-gray-200 p-1 flex gap-1';
    popover.style.display = 'none';
    document.body.appendChild(popover);
    popoverRef.current = popover;

    const acceptBtn = document.createElement('button');
    acceptBtn.className =
      'px-2 py-1 text-xs bg-green-100 hover:bg-green-200 text-green-800 rounded cursor-pointer';
    acceptBtn.textContent = 'Accept';
    popover.appendChild(acceptBtn);

    const rejectBtn = document.createElement('button');
    rejectBtn.className =
      'px-2 py-1 text-xs bg-red-100 hover:bg-red-200 text-red-800 rounded cursor-pointer';
    rejectBtn.textContent = 'Reject';
    popover.appendChild(rejectBtn);

    function hidePopover(): void {
      popover.style.display = 'none';
      cleanupRef.current?.();
      cleanupRef.current = null;
      activeChangeIdRef.current = null;
    }

    function showPopover(referenceEl: HTMLElement): void {
      cleanupRef.current?.();
      popover.style.display = 'flex';

      cleanupRef.current = autoUpdate(referenceEl, popover, () => {
        computePosition(referenceEl, popover, {
          placement: 'bottom-start',
          middleware: [offset(4), flip(), shift({ padding: 8 })],
        }).then(({ x, y }) => {
          popover.style.left = `${x}px`;
          popover.style.top = `${y}px`;
        });
      });
    }

    function resolveChange(keepType: 'insert' | 'delete'): void {
      const changeId = activeChangeIdRef.current;
      if (!changeId) return;

      editor.update(() => {
        const { deleteNode, insertNode } = $findChangeNodesById(changeId);

        if (keepType === 'insert') {
          if (insertNode) $unwrapChangeNode(insertNode);
          if (deleteNode) deleteNode.remove();
        } else {
          if (deleteNode) $unwrapChangeNode(deleteNode);
          if (insertNode) insertNode.remove();
        }
      });

      hidePopover();
    }

    acceptBtn.addEventListener('click', () => resolveChange('insert'));
    rejectBtn.addEventListener('click', () => resolveChange('delete'));

    const removeUpdateListener = editor.registerUpdateListener(({ editorState }) => {
      editorState.read(() => {
        const selection = $getSelection();
        if (!$isRangeSelection(selection)) {
          hidePopover();
          return;
        }

        const anchorNode = selection.anchor.getNode();
        const changeNode = $findChangeNode(anchorNode);

        if (!changeNode) {
          hidePopover();
          return;
        }

        activeChangeIdRef.current = changeNode.__changeId;
        const domElement = editor.getElementByKey(changeNode.getKey());
        if (!domElement) {
          hidePopover();
          return;
        }

        showPopover(domElement);
      });
    });

    return () => {
      removeUpdateListener();
      cleanupRef.current?.();
      popover.remove();
    };
  }, [editor]);

  return null;
}
