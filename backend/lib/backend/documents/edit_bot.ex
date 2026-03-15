defmodule Backend.Documents.EditBot do
  @moduledoc """
  Manages a Node.js sidecar process that can apply Lexical editor operations
  to a Yjs document via the DocServer.

  The sidecar uses Lexical's own API to make edits, ensuring the Yjs document
  structure remains valid regardless of document complexity. Communication
  happens via stdin/stdout with `{:packet, 4}` framing.

  Currently driven by a 5-second timer for demonstration. The public
  `execute_command/2` function is the intended entry point for agent-driven
  edits.
  """

  use GenServer

  alias Backend.Documents
  alias Backend.Documents.DocServer
  alias Backend.Organisations

  require Logger

  @tick_interval 5_000

  # Public API

  def start_link(opts) do
    document_id = Keyword.fetch!(opts, :document_id)
    GenServer.start_link(__MODULE__, document_id)
  end

  @doc """
  Sends a command to the sidecar and applies the resulting Yjs update
  to the document. Returns `:ok` on success or `{:error, reason}` on failure.
  """
  def execute_command(pid, command) do
    GenServer.call(pid, {:execute_command, command}, 30_000)
  end

  # Callbacks

  @impl true
  def init(document_id) do
    with {:ok, doc_server} <- DocServer.find_or_start(document_id),
         %{organisation_id: org_id} <- Documents.get(document_id),
         {:ok, agent} <- Organisations.get_agent(org_id) do
      port = open_sidecar_port()
      schedule_tick()

      {:ok,
       %{
         document_id: document_id,
         doc_server: doc_server,
         agent: agent,
         port: port,
         pending_caller: nil
       }}
    else
      nil -> {:stop, :document_not_found}
      {:error, reason} -> {:stop, reason}
    end
  end

  @impl true
  def handle_call({:execute_command, command}, from, state) do
    send_command(state.port, state.doc_server, command)
    {:noreply, %{state | pending_caller: from}}
  end

  @impl true
  def handle_info(:tick, state) do
    send_command(state.port, state.doc_server, "append_hello")
    {:noreply, state}
  end

  def handle_info({port, {:data, data}}, %{port: port} = state) do
    case Jason.decode!(data) do
      %{"ok" => true, "type" => "command", "update" => update_b64} ->
        update = Base.decode64!(update_b64)
        DocServer.apply_update(state.doc_server, update)

        maybe_reply(state.pending_caller, :ok)
        schedule_tick()
        {:noreply, %{state | pending_caller: nil}}

      %{"ok" => false, "error" => error} ->
        Logger.error("EditBot sidecar error: #{error}")

        maybe_reply(state.pending_caller, {:error, error})
        schedule_tick()
        {:noreply, %{state | pending_caller: nil}}
    end
  end

  def handle_info({port, {:exit_status, code}}, %{port: port} = state) do
    Logger.error("EditBot sidecar exited with status #{code}")
    {:stop, {:sidecar_exited, code}, state}
  end

  @impl true
  def terminate(_reason, %{port: port}) do
    Port.close(port)
  catch
    # Port may already be closed
    :error, :badarg -> :ok
  end

  # Private

  defp open_sidecar_port do
    node_path = System.find_executable("node")

    if !node_path do
      raise "node executable not found in PATH"
    end

    sidecar_path = sidecar_script_path()

    Port.open(
      {:spawn_executable, node_path},
      [
        :binary,
        :use_stdio,
        {:packet, 4},
        :exit_status,
        {:args, [sidecar_path]}
      ]
    )
  end

  defp sidecar_script_path do
    :backend
    |> :code.priv_dir()
    |> Path.join("sidecar/index.mjs")
  end

  defp send_command(port, doc_server, command) do
    {:ok, encoded_state} = DocServer.get_encoded_state(doc_server)

    payload =
      Jason.encode!(%{
        command: command,
        state: Base.encode64(encoded_state)
      })

    Port.command(port, payload)
  end

  defp schedule_tick do
    Process.send_after(self(), :tick, @tick_interval)
  end

  defp maybe_reply(nil, _response), do: :ok
  defp maybe_reply(caller, response), do: GenServer.reply(caller, response)
end
