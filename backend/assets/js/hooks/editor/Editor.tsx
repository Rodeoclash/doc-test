import type { EditorState } from 'lexical';
import type { InitialConfigType } from '@lexical/react/LexicalComposer';

import { AutoFocusPlugin } from '@lexical/react/LexicalAutoFocusPlugin';
import { LexicalComposer } from '@lexical/react/LexicalComposer';
import { RichTextPlugin } from '@lexical/react/LexicalRichTextPlugin';
import { ContentEditable } from '@lexical/react/LexicalContentEditable';
import { HistoryPlugin } from '@lexical/react/LexicalHistoryPlugin';
import { LexicalErrorBoundary } from '@lexical/react/LexicalErrorBoundary';
import { OnChangePlugin } from '@lexical/react/LexicalOnChangePlugin';
import { SectionNode } from './section';

const theme = {
  // Theme styling goes here
  //...
}

function onError(error: Error): void {
  console.error(error);
}

function loadContent(): string {
  const state = {
    "root": {
      "children": [
        {
          "type": "section",
          "version": 1,
          "sectionRef": "4.1",
          "heading": "Understanding the Organisation and Its Context",
          "direction": null,
          "format": "",
          "indent": 0,
          "children": [
            {
              "type": "paragraph",
              "version": 1,
              "direction": null,
              "format": "",
              "indent": 0,
              "textFormat": 0,
              "textStyle": "",
              "children": [
                {
                  "type": "text",
                  "version": 1,
                  "detail": 0,
                  "format": 0,
                  "mode": "normal",
                  "style": "",
                  "text": "SuperAPI is the primary operating company..."
                }
              ]
            }
          ]
        }
      ],
      "direction": null,
      "format": "",
      "indent": 0,
      "type": "root",
      "version": 1
    }
  };
  return JSON.stringify(state);
}

function onChange(editorState: EditorState): void {
  // console.log(JSON.stringify(editorState.toJSON()))
}

export default function Editor() {
  const initialConfig: InitialConfigType = {
    editorState: loadContent(),
    namespace: 'MyEditor',
    nodes: [SectionNode],
    theme,
    onError,
  };

  return (
    <LexicalComposer initialConfig={initialConfig}>
      <RichTextPlugin
        contentEditable={
          <ContentEditable
            aria-placeholder={'Enter some text...'}
            placeholder={<div>Enter some text...</div>}
          />
        }
        ErrorBoundary={LexicalErrorBoundary}
      />
      <HistoryPlugin />
      <AutoFocusPlugin />
      <OnChangePlugin onChange={onChange} />
    </LexicalComposer>
  );
}
