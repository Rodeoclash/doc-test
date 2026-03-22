import { type Klass, type LexicalNode } from "lexical";
import { HeadingNode, QuoteNode } from "@lexical/rich-text";
import { ListNode, ListItemNode } from "@lexical/list";
import { LinkNode } from "@lexical/link";

import { ChangeInsertNode } from "./hooks/editor/nodes/change_insert";
import { ChangeDeleteNode } from "./hooks/editor/nodes/change_delete";

/**
 * All node types registered with the editor. Shared between the browser
 * editor, the headless sidecar, and used to generate node descriptions
 * for the AI system prompt.
 */
export const editorNodes: Klass<LexicalNode>[] = [
  HeadingNode,
  QuoteNode,
  ListNode,
  ListItemNode,
  LinkNode,
  ChangeInsertNode,
  ChangeDeleteNode,
];

/**
 * Describes the available node types for the AI system prompt. Claude uses
 * these descriptions to understand how to read and construct valid Lexical
 * document JSON.
 */
export const nodeDescriptions = `
## Document Node Types

The document is represented as Lexical editor JSON. The root node contains an array of children which are block-level nodes.

### Built-in Nodes

**paragraph**
Block-level container for text content.
\`\`\`json
{ "type": "paragraph", "direction": "ltr", "format": "", "indent": 0, "textFormat": 0, "textStyle": "", "version": 1, "children": [...] }
\`\`\`

**heading**
Block-level heading. Tag must be "h1" through "h6".
\`\`\`json
{ "type": "heading", "tag": "h1", "direction": "ltr", "format": "", "indent": 0, "textFormat": 0, "textStyle": "", "version": 1, "children": [...] }
\`\`\`

**quote**
Block-level blockquote.
\`\`\`json
{ "type": "quote", "direction": "ltr", "format": "", "indent": 0, "textFormat": 0, "textStyle": "", "version": 1, "children": [...] }
\`\`\`

**list**
Block-level list container. listType is "bullet", "number", or "check".
\`\`\`json
{ "type": "list", "listType": "bullet", "start": 1, "tag": "ul", "direction": "ltr", "format": "", "indent": 0, "version": 1, "children": [...listitem nodes] }
\`\`\`

**listitem**
Child of a list node.
\`\`\`json
{ "type": "listitem", "value": 1, "direction": "ltr", "format": "", "indent": 0, "textFormat": 0, "textStyle": "", "version": 1, "children": [...] }
\`\`\`

**link**
Inline link node.
\`\`\`json
{ "type": "link", "url": "https://example.com", "target": null, "rel": null, "title": null, "direction": "ltr", "format": "", "indent": 0, "version": 1, "children": [...text nodes] }
\`\`\`

### Text Node

Text nodes are leaf nodes inside block-level nodes. The \`format\` field is a bitmask for inline formatting:
- 0 = plain
- 1 = bold
- 2 = italic
- 3 = bold + italic
- 4 = strikethrough
- 8 = underline
- 16 = code
- 32 = subscript
- 64 = superscript
- 128 = highlight

Combine values by adding them (e.g. bold + italic = 3, bold + underline = 9).

\`\`\`json
{ "type": "text", "text": "Hello world", "format": 0, "detail": 0, "mode": "normal", "style": "", "version": 1 }
\`\`\`

### Custom Nodes

**change-insert**
Wraps content that has been added to the document. Used for tracked changes.
\`\`\`json
{ "type": "change-insert", "direction": "ltr", "format": "", "indent": 0, "version": 1, "children": [...] }
\`\`\`

**change-delete**
Wraps content that has been removed from the document. Used for tracked changes.
\`\`\`json
{ "type": "change-delete", "direction": "ltr", "format": "", "indent": 0, "version": 1, "children": [...] }
\`\`\`
`.trim();
