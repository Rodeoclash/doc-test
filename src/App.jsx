import './App.css'

import { $getRoot, $getSelection } from 'lexical';
import { useEffect } from 'react';

import { AutoFocusPlugin } from '@lexical/react/LexicalAutoFocusPlugin';
import { LexicalComposer } from '@lexical/react/LexicalComposer';
import { RichTextPlugin } from '@lexical/react/LexicalRichTextPlugin';
import { ContentEditable } from '@lexical/react/LexicalContentEditable';
import { HistoryPlugin } from '@lexical/react/LexicalHistoryPlugin';
import { LexicalErrorBoundary } from '@lexical/react/LexicalErrorBoundary';
import { OnChangePlugin } from '@lexical/react/LexicalOnChangePlugin';

const theme = {
  // Theme styling goes here
  //...
}

// Catch any errors that occur during Lexical updates and log them
// or throw them as needed. If you don't throw them, Lexical will
// try to recover gracefully without losing user data.
function onError(error) {
  console.error(error);
}

const loadContent = async () => {
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
};

function onChange(editorState) {
  console.log(JSON.stringify(editorState.toJSON()))
}

const initialEditorState = await loadContent();

function Editor() {
  const initialConfig = {
    editorState: initialEditorState,
    namespace: 'MyEditor',
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

export default Editor