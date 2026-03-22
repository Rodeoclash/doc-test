import {
  ElementNode,
  type LexicalNode,
  type NodeKey,
  type SerializedElementNode,
  type Spread,
} from "lexical";

export type ChangeKind = "insert" | "delete";

export type SerializedChangeNode = Spread<
  { type: "change"; kind: ChangeKind; changeId: string },
  SerializedElementNode
>;

export class ChangeNode extends ElementNode {
  __kind: ChangeKind;
  __changeId: string;

  static getType(): string {
    return "change";
  }

  static clone(node: ChangeNode): ChangeNode {
    return new ChangeNode(node.__kind, node.__changeId, node.__key);
  }

  constructor(kind: ChangeKind, changeId: string, key?: NodeKey) {
    super(key);
    this.__kind = kind;
    this.__changeId = changeId;
  }

  exportJSON(): SerializedChangeNode {
    return {
      ...super.exportJSON(),
      type: "change",
      kind: this.__kind,
      changeId: this.__changeId,
    };
  }

  static importJSON(serializedNode: SerializedChangeNode): ChangeNode {
    return new ChangeNode(serializedNode.kind, serializedNode.changeId);
  }

  createDOM(): HTMLElement {
    const el = document.createElement("span");
    if (this.__kind === "insert") {
      el.className = "bg-green-100 text-green-800";
    } else {
      el.className = "line-through bg-red-100 text-red-800";
    }
    return el;
  }

  updateDOM(prevNode: ChangeNode): boolean {
    return this.__kind !== prevNode.__kind;
  }
}

export function $createChangeNode(
  kind: ChangeKind,
  changeId: string,
): ChangeNode {
  return new ChangeNode(kind, changeId);
}

export function $isChangeNode(
  node: LexicalNode | null | undefined,
): node is ChangeNode {
  return node instanceof ChangeNode;
}
