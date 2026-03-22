# Document Versioning Design

Documents follow a draft/publish lifecycle. Users edit a draft, publish it (creating a snapshot), and can start a new draft from the published version.

## Data Model

- `documents` has `status` (`:draft` / `:published`), `major_version`, and `minor_version` fields
- `document_versions` stores published snapshots with `yjs_state`, version numbers, `published_at`, and `published_by_user_id`
- Publishing reads the version from the document, creates a `DocumentVersion` snapshot, and sets status to `:published`
- Starting a new draft takes a `{major, minor}` version and sets status back to `:draft`

## Context Functions (implemented)

- `Documents.publish_document/2` — locks row, rejects if not draft, snapshots yjs_state into document_versions, sets status to published
- `Documents.start_new_draft/2` — rejects if not published, sets new version numbers and status to draft
- `Documents.list_versions/1` — returns versions ordered by published_at desc, id desc (tiebreaker for same-second publishes)
- `Documents.get_version/3` — fetches a specific version by document_id, major, minor

## Next Steps

### Step 3: DocServer gating

Reject edits when the document is published. The DocServer should check document status before processing `execute_command` calls and Yjs updates. Return an error like `{:error, :document_published}` so callers can handle it.

### Step 4: DocumentChannel changes

- Return document `status` in the channel join reply so the client knows the initial state
- Reject incoming Yjs messages (`"yjs"` events) when the document is published
- Broadcast status changes so connected clients update in real-time

### Step 5: LiveView changes

- Add publish and start new draft buttons to the document show page
- Display the current version number and status
- Wire buttons to context functions via LiveView events

### Step 6: Editor hook + React changes

- Toggle the Lexical editor to read-only mode when the document is published
- Respond to status change broadcasts from the channel to toggle mode without a page refresh
- Disable/hide editing UI elements (toolbar, formatting) when read-only

### Step 7: Version browsing

- UI to list and view previous published versions
- Load a historical version's yjs_state into a read-only editor for viewing
- Consider diffing between versions (future)
