defmodule Backend.Documents.Sidecar do
  @moduledoc false
  use GenServer

  require Logger

  # Public API

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, [])
  end

  @doc """
  Sends a command and encoded Yjs state to the sidecar, returns the update binary.
  """
  def execute(pid, command, encoded_state) do
    GenServer.call(pid, {:execute, command, encoded_state}, 30_000)
  end

  # Callbacks

  @impl true
  def init([]) do
    port = open_port()
    {:ok, %{port: port, pending_caller: nil}}
  end

  @impl true
  def handle_call({:execute, _command, _encoded_state}, _from, %{pending_caller: caller} = state)
      when not is_nil(caller) do
    {:reply, {:error, :busy}, state}
  end

  def handle_call({:execute, command, encoded_state}, from, state) do
    payload =
      Jason.encode!(%{
        command: command,
        state: Base.encode64(encoded_state)
      })

    Port.command(state.port, payload)
    {:noreply, %{state | pending_caller: from}}
  end

  @impl true
  def handle_info({port, {:data, data}}, %{port: port} = state) do
    case Jason.decode!(data) do
      %{"ok" => true, "update" => update_b64} ->
        update = Base.decode64!(update_b64)
        GenServer.reply(state.pending_caller, {:ok, update})
        {:noreply, %{state | pending_caller: nil}}

      %{"ok" => false, "error" => error} ->
        Logger.error("Sidecar error: #{error}")
        GenServer.reply(state.pending_caller, {:error, error})
        {:noreply, %{state | pending_caller: nil}}
    end
  end

  def handle_info({port, {:exit_status, code}}, %{port: port} = state) do
    Logger.error("Sidecar exited with status #{code}")
    {:stop, {:sidecar_exited, code}, state}
  end

  @impl true
  def terminate(_reason, %{port: port}) do
    Port.close(port)
  catch
    :error, :badarg -> :ok
  end

  # Private

  defp open_port do
    node_path = System.find_executable("node") || raise "node executable not found in PATH"

    sidecar_path =
      :backend
      |> :code.priv_dir()
      |> Path.join("sidecar/index.mjs")

    Port.open(
      {:spawn_executable, node_path},
      [:binary, :use_stdio, {:packet, 4}, :exit_status, {:args, [sidecar_path]}]
    )
  end
end
