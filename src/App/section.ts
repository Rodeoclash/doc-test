import {
  ElementNode,
  type LexicalNode,
  type NodeKey,
  type SerializedElementNode,
  type Spread,
} from 'lexical';

export type SerializedSectionNode = Spread<
  { heading: string; type: 'section' },
  SerializedElementNode
>;

export class SectionNode extends ElementNode {
  __heading: string;

  static getType(): string {
    return 'section';
  }

  static clone(node: SectionNode): SectionNode {
    return new SectionNode(node.__heading, node.__key);
  }

  constructor(heading: string, key?: NodeKey) {
    super(key);
    this.__heading = heading;
  }

  exportJSON(): SerializedSectionNode {
    return {
      ...super.exportJSON(),
      type: 'section',
      heading: this.__heading,
    };
  }

  static importJSON(serialisedNode: SerializedSectionNode): SectionNode {
    return new SectionNode(serialisedNode.heading);
  }

  createDOM(): HTMLElement {
    const el = document.createElement('section');
    el.style.borderLeft = '3px solid #ccc';
    el.style.paddingLeft = '1rem';
    el.style.marginBottom = '1.5rem';
    return el;
  }

  updateDOM(): boolean {
    return false;
  }
}

export function $createSectionNode(heading: string): SectionNode {
  return new SectionNode(heading);
}

export function $isSectionNode(node: LexicalNode | null | undefined): node is SectionNode {
  return node instanceof SectionNode;
}
