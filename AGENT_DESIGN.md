# Agent Design

## Agent Identity

Agents are scoped to **organisation + user**, not to individual documents or pages. One agent instance per user per organisation. The agent is a persistent assistant that follows the user across the organisation.

State: `{organisation_id, user_id}` — not `{document_id}`.

Each agent has a corresponding `User` record with `type: :agent`. The agent user is the **actor** recorded against actions (edits, publishes), but documents are not "owned" by agents. The agent acts on behalf of the human user who instructed it. The conversation record ties agent actions back to the human.

## Page Context

The agent doesn't live on a specific page. Instead, the page the user is currently viewing provides **context** that gets attached to each message. Examples:

- Viewing a document: `%{"type" => "document", "id" => 42}`
- Viewing a risk: `%{"type" => "risk", "id" => "R-003"}`

Page context is per-message, not per-conversation. Each message captures where the user was at that moment. When a user resumes an old conversation on a different page, past messages retain their original context and new messages carry the current page. Claude sees the full history and understands context shifts.

## References

Users can reference entities inline in messages using a trigger character (e.g. `@`) with autocomplete powered by Tribute.js. A single trigger can return mixed entity types (users, documents, risks, etc.) searched against organisation data.

References are stored inline in the message content using a marker syntax (e.g. `{{document:42:Compliance Policy}}`), not as a separate column. They are parsed out when needed — to build the system prompt for Claude, or to render as pills/chips in the UI.

## Agent Capabilities

The agent's capabilities grow with the organisation's data model. Claude API tools are defined as modules under `Backend.Anthropic.Tools`, each with a schema (sent to Claude) and an `execute/2` function (run locally). Claude decides which tools to call based on the conversation; your code validates and executes them.

Tools are static — defined in code, not driven from the database. New capabilities are added by creating new tool modules.

- Edit documents (via `DocServer.execute_edit/2`)
- Query risks, policies, evidence (future)
- Cross-reference entities (future)
- Assign users, update records (future)

## UI: Sidebar

The sidebar is a **LiveComponent** mounted on pages where the agent is useful (not every page — e.g. not on organisation settings). It connects to the user's agent on mount and loads recent conversation history.

On page navigation, the LiveComponent remounts. Conversation state is reloaded from persistent storage, so the reconnect is seamless.

The sidebar is **not** in the root layout — it's included per-page where it makes sense.

## Conversations & Storage

### Database (source of truth for chat history)

```
conversations
  - organisation_id
  - user_id (the human)
  - title (optional)

messages
  - conversation_id
  - role: :user / :assistant
  - content: text (with inline reference markers)
  - context: map (snapshot of where the user was)
```

### Agent State (working memory)

Jido agent state holds a compressed working context — current intent, active references, recent decisions. This is what the agent needs to act, not the full chat log.

The database stores what the user sees. The agent state stores what the agent needs to think.

### Context Management

- **Context shifts naturally** when the user navigates. The next message carries a new page context. The agent sees the shift in the data.
- **Clean breaks** via a "new conversation" button. Starts a fresh thread. Old conversations remain accessible.
- **Recovering prior contexts** through a conversation list ("recent threads"). Selecting one resumes that thread and reloads the agent's working context from its messages.

## LLM Integration

### Backend.Anthropic

Thin Elixir wrapper around the Claude API using `Req`. Calls `POST /v1/messages` with API key from application config. Supports system prompts, tools, and parses response content blocks (text and tool_use).

### Tool Loop

When Claude responds with `stop_reason: "tool_use"`, the loop executes the requested tools locally, sends results back, and repeats until Claude returns `"end_turn"`. A max iterations guard prevents runaway loops. Tools are defined as modules with a `definition/0` (JSON schema for Claude) and `execute/2` (local implementation).

### System Prompt Assembly

Each API call includes a system prompt assembled from the agent's current state:
- Organisation name
- Current page context (from the latest message)
- Available tool descriptions
- Any relevant entity details

## Concurrency

- One agent per user per org — no contention between users
- `DocServer.execute_edit/2` serializes edits through the GenServer mailbox
- Yjs CRDT handles concurrent human + agent edits (merge is conflict-free at the data level, though semantic conflicts are possible)
- During a sidecar operation, DocServer is blocked. Human edits via channels queue behind it. Acceptable for now; async execution is a future optimisation if needed.

## Process Topology

```
Backend.Jido (supervision tree)
  └── AgentServer (per user per org, started on first interaction)
        - Sends signals to DocServer when editing

DocServer (per document, globally registered via :global)
  └── Sidecar (lazily started, linked to DocServer)
        - Node.js Port for Lexical edits
```

The agent and DocServer are decoupled. The agent calls `DocServer.execute_edit/2` as a consumer. Multiple agents (different users) can call the same DocServer — edits are serialized.

## Implementation Progress

### Done

- [x] EditAgent with signal routing (`document.edit` → `ExecuteEditCommand`)
- [x] DocServer with sidecar integration (`execute_edit/2`, `:global` registry)
- [x] Sidecar GenServer (Node.js Port for headless Lexical edits)
- [x] Document versioning (draft/publish lifecycle, version snapshots)
- [x] `Backend.Anthropic` module (chat function, Req-based, tested with stubs)
- [x] Runtime config for `ANTHROPIC_API_KEY`
- [x] Conversation + Message schemas, migration, factories

### In Progress

- [ ] `Backend.Conversations` context module (create, list, add message, format for API)

### Remaining

- [ ] `list_conversations/2` — list a user's conversations in an org
- [ ] `get_conversation/1` — load a conversation with messages
- [ ] `messages_for_api/1` — format messages for `Backend.Anthropic.chat/2`
- [ ] Sidebar LiveComponent (chat UI)
- [ ] Wire sidebar → agent → Anthropic (full request loop)
- [ ] Tool loop in `Backend.Anthropic`
- [ ] Tool modules under `Backend.Anthropic.Tools`
- [ ] System prompt assembly
- [ ] Tribute.js integration for inline references
- [ ] Document versioning steps 3-7 (DocServer gating, channel changes, LiveView, editor UI)
