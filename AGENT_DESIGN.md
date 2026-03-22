# Agent Design

## Agent Identity

Agents are scoped to **organisation + user**, not to individual documents or pages. One agent instance per user per organisation. The agent is a persistent assistant that follows the user across the organisation.

State: `{organisation_id, user_id}` — not `{document_id}`.

Each agent has a corresponding `User` record with `type: :agent`. The agent user is the **actor** recorded against actions (edits, publishes), but documents are not "owned" by agents. The agent acts on behalf of the human user who instructed it. The conversation record ties agent actions back to the human.

## Message Context

The agent doesn't live on a specific page. Instead, the user's current situation provides **context** that gets attached to each message. This is not limited to page navigation — it could be any relevant state. Examples:

- Viewing a document: `%{"type" => "document", "id" => "42", "title" => "Compliance Policy", "action" => "viewing"}`
- Editing a risk: `%{"type" => "risk", "id" => "R-003", "title" => "Data Breach", "action" => "editing"}`

Context is per-message, not per-conversation. Each message captures the user's situation at that moment. When a user resumes an old conversation in a different context, past messages retain their original context and new messages carry the current one. Claude sees the full history and understands context shifts.

The context map always includes `type`, `id`, `title`, and `action`. The `id` is stored so tools can act on the referenced entity. The `title` is a snapshot (won't change if the entity is renamed later).

## References

Users can reference entities inline in messages using a trigger character (e.g. `@`) with autocomplete powered by Tribute.js. A single trigger can return mixed entity types (users, documents, risks, etc.) searched against organisation data.

References are stored inline in the message content using a marker syntax (e.g. `{{document:42:Compliance Policy}}`), not as a separate column. They are parsed out when needed — to build the system prompt for Claude, or to render as pills/chips in the UI.

## Agent Capabilities

The agent's capabilities grow with the organisation's data model. Claude API tools are defined as modules under `Backend.Anthropic.Tools`, each with a schema (sent to Claude) and an `execute/2` function (run locally). Claude decides which tools to call based on the conversation; your code validates and executes them.

Tools are static — defined in code, not driven from the database. New capabilities are added by creating new tool modules.

- Read documents (via `DocServer.execute_query/2`)
- Edit documents (via `DocServer.execute_command/2`)
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
  - content: text (markdown, with inline reference markers)
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

### Message Format (XML)

Messages sent to Claude are encoded as XML via `Backend.Conversations.MessageFormat`. Each message has two top-level nodes — `<context>` (optional, carries structured metadata as attributes) and `<content>` (the user/assistant text). The UI reads raw `content` and `context` fields from the database separately; the XML encoding is only for Claude's consumption.

```xml
<message>
  <context action="viewing" id="42" title="Compliance Policy" type="document"/>
  <content>Check this for spelling mistakes</content>
</message>
```

Uses `saxy` for XML building and parsing. The format round-trips cleanly (encode → decode preserves data).

### Tool Loop (TODO)

When Claude responds with `stop_reason: "tool_use"`, the loop executes the requested tools locally, sends results back, and repeats until Claude returns `"end_turn"`. A max iterations guard prevents runaway loops. Tools are defined as modules with a `definition/0` (JSON schema for Claude) and `execute/2` (local implementation).

### Content Format

Message content (both user and assistant) is stored as **Markdown**. The UI renders it as HTML using `earmark` with Tailwind's `@tailwindcss/typography` `prose` classes for styling. The system prompt should instruct Claude to respond in Markdown.

### System Prompt Assembly (TODO)

Each API call includes a system prompt assembled from the agent's current state:
- Organisation name
- Agent identity
- Available tool descriptions
- Any relevant entity details

## Concurrency

- One agent per user per org — no contention between users
- `DocServer.execute_command/2` serializes edits through the GenServer mailbox
- Yjs CRDT handles concurrent human + agent edits (merge is conflict-free at the data level, though semantic conflicts are possible)
- During a sidecar operation, DocServer is blocked. Human edits via channels queue behind it. Acceptable for now; async execution is a future optimisation if needed.

## Process Topology

```
Backend.Jido (supervision tree)
  └── AgentServer (per user per org, started on first interaction)
        - Sends signals to DocServer when editing

DocServer (per document, globally registered via :global)
  └── Sidecar (lazily started, monitored by DocServer)
        - Node.js Port for Lexical commands and queries
```

The agent and DocServer are decoupled. The agent calls `DocServer.execute_command/3` and `DocServer.execute_query/2` as a consumer. Multiple agents (different users) can call the same DocServer — operations are serialized.

## Next Steps

### Agent

- [ ] Wrap AI-authored content in change nodes (ChangeInsertNode/ChangeDeleteNode) so users can review and accept/reject AI edits before they become permanent
- [ ] Validate Lexical JSON from Claude — return errors to Claude for self-correction via the tool loop

### Chat UI

- [ ] Ctrl+Enter to submit the chat input
- [ ] Ability to start a new conversation
- [ ] Ability to go back in the conversation to a previous message (branching)
- [ ] AI chat outside the context of a document (e.g. organisation-level sidebar)

### Future

- [ ] Tribute.js integration for inline references
- [ ] Document versioning steps 3-7 (DocServer gating, channel changes, LiveView, editor UI)
