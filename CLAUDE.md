# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Structure

Phoenix app in `backend/` with a React/Lexical editor built via esbuild, orchestrated via Docker Compose. A `justfile` provides task runner shortcuts.

## Commands

- **Start all services:** `docker compose up` (from project root)
- **Rebuild after dependency changes:** `docker compose up --build`
- **Shell into a container:** `just shell` (defaults to backend) or `just shell <service>`
- **Run a command in a container:** `just run <service> <cmd>` (e.g. `just run backend mix test`)
- **Install editor npm deps:** `just run backend npm install --prefix assets`

## Architecture

### Backend (`backend/`)

Elixir/Phoenix app with LiveView. Uses `Dockerfile.dev` for local development (includes Node.js 22 for npm). Runs on port 4000. Waits for Postgres to be healthy before starting.

**Lexical Editor (`backend/assets/js/editor/`):** React 19 + TypeScript components built by a dedicated esbuild profile (`editor`). Outputs to `priv/static/assets/js/index.js`.

- `Editor.tsx` — Lexical editor with RichTextPlugin, HistoryPlugin, AutoFocusPlugin, OnChangePlugin. Registers the custom `SectionNode`.
- `section.ts` — `SectionNode` extends `ElementNode` for document sections with a `heading` property. Uses Tailwind classes for styling. Exports `$createSectionNode`, `$isSectionNode`, and `SerializedSectionNode` type.
- `index.tsx` — Entry point. Exports `mount(el)` and `unmount()` functions for use by LiveView hooks.

**LiveView Hook (`backend/assets/js/hooks/editor_hook.ts`):** Mounts/unmounts the React editor. Registered in `app.js` as `EditorHook`. Use in any template:

```heex
<div id="lexical-editor" phx-hook="EditorHook"></div>
```

**esbuild:** Two profiles configured in `config/config.exs` — `backend` (Phoenix/LiveView JS) and `editor` (React/Lexical TSX). Both run as watchers in dev.

**npm deps:** Managed via `backend/assets/package.json`. React, Lexical, and type definitions installed in `backend/assets/node_modules/`.

### Docker

- `docker-compose.yml` defines two services: `backend`, `postgres`
- Backend: Phoenix dev server on port 4000 via volume mount, depends on `postgres` health
- Postgres 18.2 with user/password `postgres`/`postgres`
