# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Structure

Phoenix app in `backend/` with a collaborative React/Lexical editor built via esbuild, orchestrated via Docker Compose. A `justfile` provides task runner shortcuts.

## Commands

- **Start all services:** `docker compose up` (from project root)
- **Rebuild after dependency changes:** `docker compose up --build`
- **Shell into a container:** `just shell` (defaults to backend) or `just shell <service>`
- **Run a command in a container:** `just run <service> <cmd>` (e.g. `just run backend mix test`)
- **Install editor npm deps:** `just run backend npm install --prefix assets`

## Formatting & Linting

- **Pre-commit hooks** via lefthook (`lefthook.yml`): runs Biome on JS/TS/TSX and `mix format` on Elixir files.
- **Biome** (`biome.json` at root): linter + formatter for `backend/assets/js/**`. Root `package.json` has `@biomejs/biome` and `lefthook` as dev deps.

## Architecture

### Backend (`backend/`)

Elixir/Phoenix app with LiveView. Uses `Dockerfile.dev` for local development (includes Node.js 22 for npm). Runs on port 4000. Waits for Postgres to be healthy before starting.

**JS Entry Points (`backend/assets/js/`):** Two bundles built by a single esbuild profile (`backend`) configured in `config/config.exs`:
- `public.ts` — For unauthenticated pages. Sets up LiveSocket with colocated hooks only.
- `private.ts` — For authenticated pages. Imports the Editor hook and user socket in addition to colocated hooks.
- `shared.ts` — Common `setupLiveSocket()` helper used by both entry points.

**Lexical Editor (`backend/assets/js/hooks/editor/`):** React 19 + TypeScript collaborative editor using Lexical with Yjs.

- `Editor.tsx` — Lexical editor with RichTextPlugin, CollaborationPlugin (Yjs), AutoFocusPlugin, and ChangePopoverPlugin. Registers `ChangeDeleteNode` and `ChangeInsertNode`.
- `nodes/change_delete.ts`, `nodes/change_insert.ts` — Custom Lexical nodes for tracking changes.
- `plugins/ChangePopoverPlugin.tsx` — Plugin for change review UI.

**LiveView Hook (`backend/assets/js/hooks/editor.tsx`):** Mounts/unmounts the React editor using `phoenix_typed_hook`. Registered in `private.ts` as `Editor`. Requires `data-document-id` and `data-username` attributes. Use in templates:

```heex
<div id="editor" phx-hook="Editor" data-document-id={@document.id} data-username={@current_scope.user.email}></div>
```

**Yjs Collaboration (`backend/assets/js/user_socket/`):** `PhoenixChannelProvider.ts` bridges Yjs documents over Phoenix Channels. `document_channel.ts` creates the channel connection.

**npm deps:** Managed via `backend/assets/package.json`. Key deps: React, Lexical, `y-protocols`, `@floating-ui/dom`, `phoenix_typed_hook`.

### Docker

- `docker-compose.yml` defines two services: `backend`, `postgres`
- Backend: Phoenix dev server on port 4000 via volume mount, depends on `postgres` health
- Postgres 18.2 with user/password `postgres`/`postgres`
