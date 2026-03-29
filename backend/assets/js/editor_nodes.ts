import { AutoLinkNode, LinkNode } from "@lexical/link";
import { ListItemNode, ListNode } from "@lexical/list";
import { HeadingNode, QuoteNode } from "@lexical/rich-text";
import { TableCellNode, TableNode, TableRowNode } from "@lexical/table";
import type { Klass, LexicalNode } from "lexical";

import { ChangeNode } from "./hooks/editor/nodes/change";

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
  AutoLinkNode,
  TableNode,
  TableRowNode,
  TableCellNode,
  ChangeNode,
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

### Table

Tables consist of three node types: table, tablerow, and tablecell. Cells can optionally be headers.

\`\`\`json
{
  "type": "table",
  "version": 1,
  "children": [
    {
      "type": "tablerow",
      "version": 1,
      "children": [
        { "type": "tablecell", "headerState": 1, "colSpan": 1, "version": 1, "children": [...paragraph nodes] },
        { "type": "tablecell", "headerState": 1, "colSpan": 1, "version": 1, "children": [...paragraph nodes] }
      ]
    },
    {
      "type": "tablerow",
      "version": 1,
      "children": [
        { "type": "tablecell", "headerState": 0, "colSpan": 1, "version": 1, "children": [...paragraph nodes] },
        { "type": "tablecell", "headerState": 0, "colSpan": 1, "version": 1, "children": [...paragraph nodes] }
      ]
    }
  ]
}
\`\`\`

headerState: 0 = normal cell, 1 = row header, 2 = column header, 3 = both.

### Change Node

Wraps content involved in a tracked change. The \`kind\` property indicates whether this is inserted or deleted content. Changes can appear in three patterns:

1. **Insert only** — A single change node with kind="insert". New content was added.
2. **Delete only** — A single change node with kind="delete". Content was removed.
3. **Replace** — Two change nodes sharing the same changeId: one kind="delete" (old content) and one kind="insert" (new content). They should be adjacent siblings.

When accepting a change: inserted content becomes permanent, deleted content is removed.
When rejecting a change: inserted content is removed, deleted content is restored.

\`\`\`json
{ "type": "change", "kind": "insert", "changeId": "unique-id", "direction": "ltr", "format": "", "indent": 0, "version": 1, "children": [...] }
\`\`\`
`.trim();
