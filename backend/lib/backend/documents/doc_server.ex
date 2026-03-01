defmodule Backend.Documents.DocServer do
  @moduledoc false
  use Yex.DocServer

  alias Backend.Documents

  require Logger

  # Public API

  def find_or_start(document_id) do
    case Registry.lookup(Backend.DocRegistry, document_id) do
      [{pid, _}] ->
        Logger.info("DocServer already running for document #{document_id} (#{inspect(pid)})")
        {:ok, pid}

      [] ->
        Logger.info("Starting DocServer for document #{document_id}")

        DynamicSupervisor.start_child(
          Backend.DocSupervisor,
          {__MODULE__, document_id}
        )
    end
  end

  def child_spec(document_id) do
    %{
      id: {__MODULE__, document_id},
      start:
        {__MODULE__, :start_link,
         [[document_id: document_id], [name: {:via, Registry, {Backend.DocRegistry, document_id}}]]}
    }
  end

  # Callbacks

  @impl true
  def init(arg, state) do
    document_id = Keyword.fetch!(arg, :document_id)
    document = Documents.get(document_id)

    if is_nil(document) do
      Logger.error("DocServer failed to start: document #{document_id} not found")
      {:stop, :document_not_found}
    else
      Logger.info("DocServer started for document #{document_id}")

      # Apply persisted Yjs state if it exists
      if document.yjs_state do
        Yex.apply_update(state.doc, document.yjs_state)
      end

      {:ok, Map.merge(state, %{document_id: document_id, topic: "document:#{document_id}"})}
    end
  end

  @impl true
  def handle_update_v1(_doc, update, origin, state) do
    # Persist the full document state to the database
    {:ok, encoded} = Yex.encode_state_as_update(state.doc)
    Documents.update_yjs_state(state.document_id, encoded)

    # Broadcast the incremental update to other clients
    message = Yex.Sync.message_encode(Yex.Sync.get_update(update))

    BackendWeb.Endpoint.broadcast_from(
      origin,
      state.topic,
      "yjs",
      %{"data" => Base.encode64(message)}
    )

    {:noreply, state}
  end
end
