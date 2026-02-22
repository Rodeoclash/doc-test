import { ElementNode } from 'lexical';

export class SectionNode extends ElementNode {
  __sectionRef;  // e.g. "4.1"
  __heading;     // e.g. "Understanding the Organisation"

  static getType() {
    return 'section';
  }

  static clone(node) {
    return new SectionNode(node.__sectionRef, node.__heading, node.__key);
  }

  constructor(sectionRef, heading, key) {
    super(key);
    this.__sectionRef = sectionRef;
    this.__heading = heading;
  }

  // Serialise to JSON (for storage / your mirror)
  exportJSON() {
    return {
      ...super.exportJSON(),
      type: 'section',
      sectionRef: this.__sectionRef,
      heading: this.__heading,
    };
  }

  // Deserialise from JSON
  static importJSON(serialisedNode) {
    return new SectionNode(serialisedNode.sectionRef, serialisedNode.heading);
  }

  // How it renders in the editor
  createDOM() {
    const el = document.createElement('section');
    el.setAttribute('data-section-ref', this.__sectionRef);
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
export function $createSectionNode(sectionRef, heading) {
  return new SectionNode(sectionRef, heading);
}

export function $isSectionNode(node) {
  return node instanceof SectionNode;
}