import {
  ElementNode,
  type LexicalNode,
  type NodeKey,
  type SerializedElementNode,
  type Spread,
} from 'lexical';

export type SerializedChangeInsertNode = Spread<
  { type: 'change-insert'; changeId: string },
  SerializedElementNode
>;

export class ChangeInsertNode extends ElementNode {
  __changeId: string;

  static getType(): string {
    return 'change-insert';
  }

  static clone(node: ChangeInsertNode): ChangeInsertNode {
    return new ChangeInsertNode(node.__changeId, node.__key);
  }

  constructor(changeId: string, key?: NodeKey) {
    super(key);
    this.__changeId = changeId;
  }

  exportJSON(): SerializedChangeInsertNode {
    return {
      ...super.exportJSON(),
      type: 'change-insert',
      changeId: this.__changeId,
    };
  }

  static importJSON(serializedNode: SerializedChangeInsertNode): ChangeInsertNode {
    return new ChangeInsertNode(serializedNode.changeId);
  }

  createDOM(): HTMLElement {
    const el = document.createElement('span');
    el.className = 'bg-green-100 text-green-800';
    return el;
  }

  updateDOM(): boolean {
    return false;
  }
}

export function $createChangeInsertNode(changeId: string): ChangeInsertNode {
  return new ChangeInsertNode(changeId);
}

export function $isChangeInsertNode(node: LexicalNode | null | undefined): node is ChangeInsertNode {
  return node instanceof ChangeInsertNode;
}
