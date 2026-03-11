# Agent Design

## Agent Identity

Agents are scoped to **organisation + user**, not to individual documents or pages. One agent instance per user per organisation. The agent is a persistent assistant that follows the user across the organisation.

State: `{organisation_id, user_id}` — not `{document_id}`.

## Page Context

The agent doesn't live on a specific page. Instead, the page the user is currently viewing provides **context** that gets attached to signals. Examples:

- Viewing a document: `%{type: :document, id: 42}`
- Viewing a risk: `%{type: :risk, id: "R-003"}`

Page context is implicit ("I'm looking at this right now"). It changes as the user navigates.

## References

Users can explicitly reference entities in chat messages using mention syntax (e.g. `@Sam`, `#Doc-42`). These are resolved to structured references before being sent to the agent:

```elixir
%{
  message: "rewrite the intro",
  references: [
    %{type: :document, id: 42, label: "compliance policy"}
  ],
  page_context: %{type: :document, id: 42}
}
```

The chat input provides autocomplete when a trigger character is typed, searching against organisation data. References are explicit — distinct from page context, though they may overlap.

## Agent Capabilities

The agent's capabilities grow with the organisation's data model. Actions are added as new signal routes:

- Edit documents (today, via `DocServer.execute_edit/2`)
- Query risks, policies, evidence (future)
- Cross-reference entities (future)
- Assign users, update records (future)

All actions operate within the organisation scope. Document access comes through signal data, not agent identity.

## UI: Sidebar

The sidebar is a **LiveComponent** mounted on pages where the agent is useful (not every page — e.g. not on organisation settings). It connects to the user's agent on mount and loads recent conversation history.

On page navigation, the LiveComponent remounts. Conversation state is reloaded from persistent storage, so the reconnect is seamless.

The sidebar is **not** in the root layout — it's included per-page where it makes sense.

## Conversations & Storage

### Database (source of truth for chat history)

```
Conversation (belongs_to organisation + user)
  - Messages (ordered)
    - role: :user / :agent
    - content: text
    - references: [%{type, id, label}]
    - context: %{type, id} (page context at time of message)
```

### Agent State (working memory)

Jido agent state holds a compressed working context — current intent, active references, recent decisions. This is what the agent needs to act, not the full chat log.

The database stores what the user sees. The agent state stores what the agent needs to think.

### Context Management

- **Context shifts naturally** when the user navigates. The next message carries a new page context. The agent sees the shift in the data.
- **Clean breaks** via a "new conversation" button. Starts a fresh thread. Old conversations remain accessible.
- **Recovering prior contexts** through a conversation list ("recent threads"). Selecting one resumes that thread and reloads the agent's working context from its messages.

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
