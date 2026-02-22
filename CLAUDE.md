# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Structure

Monorepo with `frontend/` and `backend/` directories, orchestrated via Docker Compose.

## Commands

- **Start all services:** `docker compose up` (from project root)
- **Rebuild after dependency changes:** `docker compose up --build`
- **Frontend only (without Docker):** `cd frontend && npm run dev`

### Frontend commands (run from `frontend/`)

- **Dev server:** `npm run dev`
- **Build:** `npm run build` (type-checks with tsc, then bundles with Vite)
- **Lint:** `npm run lint` (ESLint with typescript-eslint, react-hooks, and react-refresh plugins)
- **Type-check:** `npm run type-check` (runs `tsc --noEmit`)
- **Preview production build:** `npm run preview`

## Architecture

### Frontend (`frontend/`)

React 19 + Vite 7 + TypeScript + Tailwind CSS v4 app using Lexical as a rich-text editor framework. Tailwind is integrated via `@tailwindcss/vite` plugin (no `tailwind.config.js` or PostCSS config — v4 uses CSS-first configuration via `@import "tailwindcss"` in `src/index.css`).

**Entry point:** `src/main.tsx` renders `<App />` (exported from `src/App.tsx`) into `#root`.

**Editor (`src/App.tsx`):** Sets up a Lexical editor via `LexicalComposer` with RichTextPlugin, HistoryPlugin, AutoFocusPlugin, and OnChangePlugin. Editor state is initialized from a hardcoded JSON structure via `loadContent()`. Changes are logged to console via `onChange`.

**Custom Lexical node (`src/App/section.ts`):** `SectionNode` extends `ElementNode` to represent document sections with a `heading` property. Renders as a `<section>` element with a left border. Exports `$createSectionNode`, `$isSectionNode` helpers, and the `SerializedSectionNode` type. Custom serialized node types use the `Spread<CustomFields, SerializedElementNode>` pattern from Lexical.

### Docker

- `docker-compose.yml` at project root defines the services
- Frontend runs Vite dev server on port 5173 with HMR via volume mount

## ESLint

Uses `typescript-eslint` for TypeScript-aware linting. The `@typescript-eslint/no-unused-vars` rule ignores variables starting with an uppercase letter or underscore (`varsIgnorePattern: '^[A-Z_]'`).
