# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Structure

Phoenix app in `backend/` with a collaborative React/Lexical editor built via esbuild, orchestrated via Docker Compose. A `justfile` provides task runner shortcuts.

## Commands

- **Start all services:** `docker compose up` (from project root)
- **Rebuild after dependency changes:** `docker compose up --build`
- **Shell into a container:** `just shell` (defaults to backend) or `just shell <service>`
- **Run a command in a container:** `just run <service> <cmd>` (e.g. `just run backend mix test`)
- **Run tests:** `docker compose exec backend mix test` (services must be running)
- **Install editor npm deps:** `just run backend npm install --prefix assets`

## Formatting & Linting

- **Pre-commit hooks** via lefthook (`lefthook.yml`): runs Biome on JS/TS/TSX and `mix format` on Elixir files.
- **Biome** (`biome.json` at root): linter + formatter for `backend/assets/js/**`. Root `package.json` has `@biomejs/biome` and `lefthook` as dev deps.
- **Styler** (`styler` dep): Elixir code style enforcer, runs in dev/test.

## Architecture

### Backend (`backend/`)

Elixir/Phoenix app with LiveView. Uses `Dockerfile.dev` for local development (includes Node.js 22 for npm). Runs on port 4000. Waits for Postgres to be healthy before starting.

### Data Model

- **User** (`accounts/user.ex`) — Has `type` enum (`:human`, `:agent`). Humans have passwords, agents cannot (enforced by DB check constraint).
- **Organisation** (`organisations/organisation.ex`) — Has many documents.
- **OrganisationUser** (`organisations/organisation_user.ex`) — Join table linking users to organisations via `has_many, through:` (not `many_to_many`). Unique index on `[:organisation_id, :user_id]`.
- **Document** (`documents/document.ex`) — Belongs to organisation. Stores `yjs_state` binary for collaborative editing.

Users register without an organisation. Organisation membership is managed separately via the join table.

### Jido Agent Framework

`Backend.Jido` (`lib/backend/jido.ex`) — Application-wide Jido instance, added to the supervision tree. Provides `start_agent/2`, `stop_agent/1`.

- **EditAgent** (`agents/edit_agent.ex`) — Jido agent with `document_id` and `last_command` state. Signal route: `"document.edit"` → `ExecuteEditCommand`.
- **ExecuteEditCommand** (`agents/actions/execute_edit_command.ex`) — Pure Jido action that records a command against the document.
- Agents are testable as pure functions via `Agent.cmd/2` or as running processes via `Backend.Jido.start_agent/2` + `Jido.AgentServer.call/2`.

### Document Server & EditBot

- **DocServer** (`documents/doc_server.ex`) — GenServer managing Yjs document state per document. Uses Registry (`Backend.DocRegistry`) and DynamicSupervisor (`Backend.DocSupervisor`). Provides `get_encoded_state/1`, `apply_update/2`, `find_or_start/1`.
- **EditBot** (`documents/edit_bot.ex`) — GenServer that communicates with a Node.js sidecar via Port (`{:packet, 4}` framing). Sends edit commands to headless Lexical, applies resulting Yjs updates back to DocServer.

### Layouts

- **`root_public.html.heex`** — Public pages. Simple nav with auth links.
- **`root_organisation.html.heex`** — Authenticated pages. Two-column grid: 16rem sidebar (org name, user email, settings/logout links) + main content. Full viewport height (`h-dvh`).
- No dark mode. Single light theme. Plain sans-serif font.

### JS Entry Points (`backend/assets/js/`)

Two bundles built by a single esbuild profile (`backend`) configured in `config/config.exs`:
- `public.ts` — Unauthenticated pages. LiveSocket with colocated hooks only.
- `private.ts` — Authenticated pages. Imports the Editor hook and user socket.
- `shared.ts` — Common `setupLiveSocket()` helper.

### Lexical Editor (`backend/assets/js/hooks/editor/`)

React 19 + TypeScript collaborative editor using Lexical with Yjs.

- `Editor.tsx` — Lexical editor with RichTextPlugin, CollaborationPlugin (Yjs), AutoFocusPlugin, ChangePopoverPlugin. Registers `ChangeDeleteNode` and `ChangeInsertNode`.
- `nodes/change_delete.ts`, `nodes/change_insert.ts` — Custom Lexical nodes for tracking changes.
- `plugins/ChangePopoverPlugin.tsx` — Plugin for change review UI.

**LiveView Hook** (`backend/assets/js/hooks/editor.tsx`): Mounts/unmounts the React editor via `phoenix_typed_hook`. Registered in `private.ts` as `Editor`. Use in templates:

```heex
<div id="editor" phx-hook="Editor" data-document-id={@document.id} data-username={@current_scope.user.email}></div>
```

### Node.js Sidecar (`backend/assets/js/sidecar.ts`)

Long-running Node.js process that applies Lexical edits to Yjs documents. Built by a separate esbuild profile (`sidecar`) to `priv/sidecar/index.mjs`. Communicates with EditBot via stdin/stdout using `{:packet, 4}` framing (4-byte big-endian length prefix, JSON payloads).

Pipeline per request: receives `{ command, state (base64) }` → creates Y.Doc from state → creates headless Lexical editor with `@lexical/yjs` binding → executes the named command → captures Yjs updates → returns `{ ok, update (base64) }`. Registers `ChangeInsertNode` and `ChangeDeleteNode` so documents containing change nodes load without errors. Exits cleanly when stdin closes (Elixir process died).

### Document Show Page

Two-column grid: editor on the left, 20rem sidebar on the right with "AI agent chat" placeholder. Route: `/organisations/:organisation_id/documents/:id`.

### Yjs Collaboration (`backend/assets/js/user_socket/`)

`PhoenixChannelProvider.ts` bridges Yjs documents over Phoenix Channels. `document_channel.ex` handles `"yjs"` messages and starts DocServer on join.

### Docker

- `docker-compose.yml` defines two services: `backend`, `postgres`
- Backend: Phoenix dev server on port 4000 via volume mount, depends on `postgres` health
- Postgres 18.2 with user/password `postgres`/`postgres`
