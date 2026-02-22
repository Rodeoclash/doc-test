# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

- **Dev server:** `npm run dev` (Vite with HMR)
- **Build:** `npm run build`
- **Lint:** `npm run lint` (ESLint with react-hooks and react-refresh plugins)
- **Preview production build:** `npm run preview`

## Architecture

React 19 + Vite 7 app using Lexical as a rich-text editor framework.

**Entry point:** `src/main.jsx` renders `<App />` (exported from `src/App.jsx`) into `#root`.

**Editor (`src/App.jsx`):** Sets up a Lexical editor via `LexicalComposer` with RichTextPlugin, HistoryPlugin, AutoFocusPlugin, and OnChangePlugin. Editor state is initialized from a hardcoded JSON structure via `loadContent()`. Changes are logged to console via `onChange`.

**Custom Lexical node (`src/App/section.js`):** `SectionNode` extends `ElementNode` to represent document sections with a `heading` property. Renders as a `<section>` element with a left border. Exports `$createSectionNode` and `$isSectionNode` helpers.

## ESLint

The `no-unused-vars` rule ignores variables starting with an uppercase letter or underscore (`varsIgnorePattern: '^[A-Z_]'`).
