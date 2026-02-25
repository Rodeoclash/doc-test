import {
  ElementNode,
  type LexicalNode,
  type NodeKey,
  type SerializedElementNode,
  type Spread,
} from 'lexical';

export type SerializedChangeDeleteNode = Spread<
  { type: 'change-delete'; changeId: string },
  SerializedElementNode
>;

export class ChangeDeleteNode extends ElementNode {
  __changeId: string;

  static getType(): string {
    return 'change-delete';
  }

  static clone(node: ChangeDeleteNode): ChangeDeleteNode {
    return new ChangeDeleteNode(node.__changeId, node.__key);
  }

  constructor(changeId: string, key?: NodeKey) {
    super(key);
    this.__changeId = changeId;
  }

  exportJSON(): SerializedChangeDeleteNode {
    return {
      ...super.exportJSON(),
      type: 'change-delete',
      changeId: this.__changeId,
    };
  }

  static importJSON(serializedNode: SerializedChangeDeleteNode): ChangeDeleteNode {
    return new ChangeDeleteNode(serializedNode.changeId);
  }

  createDOM(): HTMLElement {
    const el = document.createElement('span');
    el.className = 'line-through bg-red-100 text-red-800';
    return el;
  }

  updateDOM(): boolean {
    return false;
  }
}

export function $createChangeDeleteNode(changeId: string): ChangeDeleteNode {
  return new ChangeDeleteNode(changeId);
}

export function $isChangeDeleteNode(node: LexicalNode | null | undefined): node is ChangeDeleteNode {
  return node instanceof ChangeDeleteNode;
}
