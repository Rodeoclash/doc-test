defmodule Backend.Documents.DocServer do
  @moduledoc false
  use Yex.DocServer

  alias Backend.Documents

  require Logger

  # Public API

  @doc """
  Returns the full Yjs document state as an encoded binary.
  """
  def get_encoded_state(doc_server) do
    GenServer.call(doc_server, :get_encoded_state)
  end

  @doc """
  Applies a Yjs update binary to the document. Triggers persistence and broadcast.
  """
  def apply_update(doc_server, update) do
    GenServer.call(doc_server, {:apply_update, update})
  end

  @doc """
  Finds a running DocServer for the given document or starts one.
  """
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
  def handle_call(:get_encoded_state, _from, state) do
    {:reply, Yex.encode_state_as_update(state.doc), state}
  end

  @impl true
  def handle_call({:apply_update, update}, _from, state) do
    Yex.apply_update(state.doc, update)
    {:reply, :ok, state}
  end

  @impl true
  def init(arg, state) do
    document_id = Keyword.fetch!(arg, :document_id)
    document = Documents.get(document_id)

    if is_nil(document) do
      Logger.error("DocServer failed to start: document #{document_id} not found")
      {:stop, :document_not_found}
    else
      Logger.info("DocServer started for document #{document_id}")

      # Apply persisted Yjs state if it exists.
      # Use :restore origin so handle_update_v1 skips persist/broadcast.
      if document.yjs_state do
        Yex.Doc.transaction(state.doc, :restore, fn ->
          Yex.apply_update(state.doc, document.yjs_state)
        end)
      end

      {:ok, Map.merge(state, %{document_id: document_id, topic: Documents.topic(document_id)})}
    end
  end

  @impl true
  def handle_update_v1(_doc, _update, :restore, state) do
    # Skip persist/broadcast when restoring state from DB during init
    {:noreply, state}
  end

  def handle_update_v1(_doc, update, origin, state) do
    # Persist the full document state to the database
    {:ok, encoded} = Yex.encode_state_as_update(state.doc)
    Documents.update_yjs_state(state.document_id, encoded)

    # Broadcast the incremental update to other clients
    {:ok, sync_update} = Yex.Sync.get_update(update)
    {:ok, message} = Yex.Sync.message_encode({:sync, sync_update})
    payload = %{"data" => Base.encode64(message)}

    if is_pid(origin) do
      BackendWeb.Endpoint.broadcast_from(origin, state.topic, "yjs", payload)
    else
      BackendWeb.Endpoint.broadcast(state.topic, "yjs", payload)
    end

    {:noreply, state}
  end
end
