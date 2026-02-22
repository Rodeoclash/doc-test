import { ElementNode } from 'lexical';

export class SectionNode extends ElementNode {
  __heading;

  static getType() {
    return 'section';
  }

  static clone(node) {
    return new SectionNode(node.__heading, node.__key);
  }

  constructor(heading, key) {
    super(key);
    this.__heading = heading;
  }

  // Serialise to JSON (for storage / your mirror)
  exportJSON() {
    return {
      ...super.exportJSON(),
      type: 'section',
      heading: this.__heading,
    };
  }

  // Deserialise from JSON
  static importJSON(serialisedNode) {
    return new SectionNode(serialisedNode.heading);
  }

  // How it renders in the editor
  createDOM() {
    const el = document.createElement('section');
    el.style.borderLeft = '3px solid #ccc';
    el.style.paddingLeft = '1rem';
    el.style.marginBottom = '1.5rem';
    return el;
  }

  updateDOM() {
    return false;
  }
}

// Helper to create one from within editor commands
export function $createSectionNode(heading) {
  return new SectionNode(heading);
}

export function $isSectionNode(node) {
  return node instanceof SectionNode;
}