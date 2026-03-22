defmodule Backend.Documents.DocServer do
  @moduledoc false
  use Yex.DocServer

  alias Backend.Documents
  alias Backend.Documents.Sidecar

  require Logger

  @sidecar_timeout 30_000

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
  Executes an edit command via the sidecar. Lazily starts the sidecar on first use.
  Gets current state, sends to sidecar, applies the resulting update.
  """
  def execute_command(doc_server, command) do
    GenServer.call(doc_server, {:execute_command, command}, @sidecar_timeout)
  end

  @doc """
  Executes a read-only query via the sidecar. Returns the Lexical editor state as JSON.
  """
  def execute_query(doc_server, query) do
    GenServer.call(doc_server, {:execute_query, query}, @sidecar_timeout)
  end

  @doc """
  Finds a running DocServer for the given document or starts one.
  """
  def find_or_start(document_id) do
    case :global.whereis_name({__MODULE__, document_id}) do
      :undefined ->
        Logger.info("Starting DocServer for document #{document_id}")

        DynamicSupervisor.start_child(
          Backend.DocSupervisor,
          {__MODULE__, document_id}
        )

      pid ->
        Logger.info("DocServer already running for document #{document_id} (#{inspect(pid)})")
        {:ok, pid}
    end
  end

  def child_spec(document_id) do
    %{
      id: {__MODULE__, document_id},
      start: {__MODULE__, :start_link, [[document_id: document_id], [name: {:global, {__MODULE__, document_id}}]]}
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

  def handle_call({:execute_command, command}, _from, state) do
    {:ok, state} = ensure_sidecar(state)
    {:ok, encoded_state} = Yex.encode_state_as_update(state.doc)

    case Sidecar.execute(state.sidecar, command, encoded_state) do
      {:ok, %{type: :command, update: update, data: data}} ->
        Yex.apply_update(state.doc, update)
        {:reply, {:ok, data}, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:execute_query, query}, _from, state) do
    {:ok, state} = ensure_sidecar(state)
    {:ok, encoded_state} = Yex.encode_state_as_update(state.doc)

    case Sidecar.execute(state.sidecar, query, encoded_state) do
      {:ok, %{type: :query, data: data}} ->
        {:reply, {:ok, data}, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
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

      {:ok,
       Map.merge(state, %{
         document_id: document_id,
         topic: Documents.topic(document_id),
         sidecar: nil
       })}
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

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, %{sidecar: pid} = state) do
    Logger.warning("Sidecar process died for document #{state.document_id}")
    {:noreply, %{state | sidecar: nil}}
  end

  # Private

  defp ensure_sidecar(%{sidecar: pid} = state) when is_pid(pid) do
    if Process.alive?(pid) do
      {:ok, state}
    else
      start_sidecar(state)
    end
  end

  defp ensure_sidecar(state), do: start_sidecar(state)

  defp start_sidecar(state) do
    case Sidecar.start_link() do
      {:ok, pid} ->
        Process.monitor(pid)
        {:ok, %{state | sidecar: pid}}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
