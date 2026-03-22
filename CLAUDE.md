# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Structure

Phoenix app in `backend/` with a collaborative React/Lexical editor built via esbuild, orchestrated via Docker Compose. A `justfile` provides task runner shortcuts.

## Commands

- **Start all services:** `just start` or `docker compose up` (from project root)
- **Rebuild after dependency changes:** `docker compose up --build`
- **Shell into a container:** `just shell` (defaults to backend) or `just shell <service>`
- **Run a command in a container:** `just run <service> <cmd>` (e.g. `just run backend mix test`)
- **Run tests:** `docker compose exec backend mix test` (services must be running)
- **IEx console on running server:** `just console`
- **Reset database:** `just reset-db` (drop, create, migrate, seed)
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
- **Document** (`documents/document.ex`) — Belongs to organisation. Stores `yjs_state` binary for collaborative editing. Has `status` (`:draft`/`:published`), `major_version`, `minor_version`.
- **DocumentVersion** (`documents/document_version.ex`) — Published snapshot of a document. Stores `yjs_state`, version numbers, `published_at`, `published_by_user_id`.
- **Conversation** (`conversations/conversation.ex`) — Chat conversation scoped to an organisation and user.
- **Message** (`conversations/message.ex`) — Chat message with `role` (`:user`/`:assistant`), `content`, and optional `context` map (stores page context at time of sending).

Users register without an organisation. Organisation membership is managed separately via the join table.

### Jido Agent Framework

`Backend.Jido` (`lib/backend/jido.ex`) — Application-wide Jido instance, added to the supervision tree. Provides `start_agent/2`, `stop_agent/1`.

- **EditAgent** (`agents/edit_agent.ex`) — Jido agent with `document_id` and `last_command` state. Signal route: `"document.edit"` → `ExecuteEditCommand`.
- **ExecuteEditCommand** (`agents/actions/execute_edit_command.ex`) — Pure Jido action that records a command against the document.
- Agents are testable as pure functions via `Agent.cmd/2` or as running processes via `Backend.Jido.start_agent/2` + `Jido.AgentServer.call/2`.

### Document Server

- **DocServer** (`documents/doc_server.ex`) — GenServer managing Yjs document state per document. Uses `:global` registry and DynamicSupervisor (`Backend.DocSupervisor`). Provides `get_encoded_state/1`, `apply_update/2`, `find_or_start/1`, `execute_command/3`, `execute_query/2`. Lazily starts and monitors a Sidecar process for interacting with Lexical.

### Layouts

- **`root_public.html.heex`** — Public pages. Simple nav with auth links.
- **`root_organisation.html.heex`** — Authenticated pages. Two-column grid: 16rem sidebar (org name, user email, settings/logout links) + main content. Full viewport height (`h-dvh`).
- No dark mode. Single light theme. Plain sans-serif font.

### JS Entry Points (`backend/assets/js/`)

Two bundles built by a single esbuild profile (`backend`) configured in `config/config.exs`:
- `public.ts` — Unauthenticated pages. LiveSocket with colocated hooks only.
- `private.ts` — Authenticated pages. Imports Editor, AutoResize, ScrollToBottom, and SubmitOnShortcut hooks plus user socket.
- `shared.ts` — Common `setupLiveSocket()` helper.
- `editor_nodes.ts` — Shared node registry (single source of truth for browser editor and sidecar). Also exports `nodeDescriptions` for AI system prompt generation.

### Lexical Editor (`backend/assets/js/hooks/editor/`)

React 19 + TypeScript collaborative editor using Lexical with Yjs.

- `Editor.tsx` — Lexical editor with RichTextPlugin, CollaborationPlugin (Yjs), AutoFocusPlugin, ChangePopoverPlugin. Uses shared `editorNodes` from `editor_nodes.ts`.
- `nodes/change_delete.ts`, `nodes/change_insert.ts` — Custom Lexical nodes for tracking changes.
- `plugins/ChangePopoverPlugin.tsx` — Plugin for change review UI.

**LiveView Hook** (`backend/assets/js/hooks/editor.tsx`): Mounts/unmounts the React editor via `phoenix_typed_hook`. Registered in `private.ts` as `Editor`. Use in templates:

```heex
<div id="editor" phx-hook="Editor" data-document-id={@document.id} data-username={@current_scope.user.email}></div>
```

### Node.js Sidecar (`backend/assets/js/sidecar.ts`)

Long-running Node.js process for headless Lexical operations on Yjs documents. Uses `@lexical/headless` with `@lexical/yjs` binding for proper Yjs↔Lexical sync. Built by a separate esbuild profile (`sidecar`) to `priv/sidecar/index.mjs`. Communicates with the Sidecar GenServer via stdin/stdout using `{:packet, 4}` framing (4-byte big-endian length prefix, JSON payloads).

Supports two operation types: **commands** (mutate the document, return Yjs update + Lexical JSON) and **queries** (read-only, return Lexical JSON). Pipeline: receives `{ command, state (base64), data }` → creates Y.Doc → creates headless editor with Yjs binding and observer → applies state → executes handler → returns `{ ok, type, data/update }`. Uses shared `editorNodes` from `editor_nodes.ts`. Exits cleanly when stdin closes (Elixir process died).

Current commands: `apply_document` (replaces document content with provided Lexical JSON). Current queries: `read_document` (returns Lexical editor state as JSON).

### AI Integration (`backend/lib/backend/anthropic/`)

- **`Anthropic`** — Claude API client. `chat/2` for plain messages, `run/2` for tool-use loop (iterates until `end_turn` or max 10 iterations). When no tools are provided, `run/2` falls back to `chat/2`.
- **`SystemPrompt`** — Builds context-aware system prompts. Base instructions always included; per-capability sections added conditionally (e.g. node descriptions for `document_tools`). Extend by adding `capability_instructions/1` clauses.
- **`Tools`** — Capability-grouped tool registry. `definitions/1` takes a capabilities list and returns the union of matching tool groups. Extend by adding tool modules and a new entry in `@tool_groups`.
- **`Tools.ReadDocument`** — Reads document content via DocServer/sidecar, returns Lexical JSON.
- **`Tools.EditDocument`** — Applies complete Lexical JSON to a document via DocServer/sidecar.

### Chat Sidebar (`backend/lib/backend_web/live/chat_live/`)

LiveView component rendered via `live_render` from parent pages. Receives `context` map (including `"capabilities"`) through the session. Capabilities drive which tools and system prompt sections are used. Messages store the page context at time of sending.

### Document Show Page

Two-column grid: editor on the left, 20rem sidebar on the right with AI chat. Route: `/organisations/:organisation_id/documents/:id`. Passes `"capabilities" => ["document_tools"]` to the sidebar.

### Build-time Generation

Node descriptions for the AI system prompt are generated at build time. `generate_node_descriptions.ts` imports `nodeDescriptions` from `editor_nodes.ts`, esbuild bundles it, Node runs it, and it writes `priv/node_descriptions.md`. The `SystemPrompt` module reads this file at compile time. The intermediate `.mjs` file is cleaned up after generation. Both are gitignored.

### Yjs Collaboration (`backend/assets/js/user_socket/`)

`PhoenixChannelProvider.ts` bridges Yjs documents over Phoenix Channels. `document_channel.ex` handles `"yjs"` messages and starts DocServer on join.

### Docker

- `docker-compose.yml` defines two services: `backend`, `postgres`
- Backend: Phoenix dev server on port 4000 via volume mount, depends on `postgres` health
- Postgres 18.2 with user/password `postgres`/`postgres`
