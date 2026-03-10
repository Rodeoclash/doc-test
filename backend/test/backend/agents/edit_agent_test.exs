defmodule Backend.Agents.EditAgentTest do
  use ExUnit.Case, async: true

  alias Backend.Agents.Actions.ExecuteEditCommand
  alias Backend.Agents.EditAgent

  describe "new/1" do
    test "creates an agent with default state" do
      agent = EditAgent.new(state: %{document_id: 1})
      assert agent.state.document_id == 1
      assert agent.state.last_command == nil
    end
  end

  describe "cmd/2" do
    test "executes an edit command and updates state" do
      agent = EditAgent.new(state: %{document_id: 1})

      {agent, _directives} =
        EditAgent.cmd(agent, {ExecuteEditCommand, %{command: "append_hello"}})

      assert agent.state.last_command == "append_hello"
    end

    test "executes multiple commands in sequence" do
      agent = EditAgent.new(state: %{document_id: 1})

      {agent, _directives} =
        EditAgent.cmd(agent, [
          {ExecuteEditCommand, %{command: "first"}},
          {ExecuteEditCommand, %{command: "second"}}
        ])

      assert agent.state.last_command == "second"
    end

    test "preserves document_id across commands" do
      agent = EditAgent.new(state: %{document_id: 42})

      {agent, _directives} =
        EditAgent.cmd(agent, {ExecuteEditCommand, %{command: "test"}})

      assert agent.state.document_id == 42
    end
  end

  describe "signal_routes/0" do
    test "routes document.edit to ExecuteEditCommand" do
      routes = EditAgent.signal_routes()
      assert {"document.edit", ExecuteEditCommand} in routes
    end
  end

  describe "signal routing via AgentServer" do
    setup do
      {:ok, pid} =
        Backend.Jido.start_agent(EditAgent,
          id: "edit-agent-#{System.unique_integer([:positive])}",
          initial_state: %{document_id: 1}
        )

      on_exit(fn ->
        try do
          GenServer.stop(pid)
        catch
          :exit, _ -> :ok
        end
      end)

      %{pid: pid}
    end

    test "processes a document.edit signal", %{pid: pid} do
      signal = Jido.Signal.new!("document.edit", %{command: "append_hello"}, source: "/test")

      {:ok, agent} = Jido.AgentServer.call(pid, signal)

      assert agent.state.last_command == "append_hello"
      assert agent.state.document_id == 1
    end

    test "processes multiple signals sequentially", %{pid: pid} do
      first = Jido.Signal.new!("document.edit", %{command: "first"}, source: "/test")
      second = Jido.Signal.new!("document.edit", %{command: "second"}, source: "/test")

      {:ok, _agent} = Jido.AgentServer.call(pid, first)
      {:ok, agent} = Jido.AgentServer.call(pid, second)

      assert agent.state.last_command == "second"
    end

    test "returns error for unrouted signal", %{pid: pid} do
      signal = Jido.Signal.new!("unknown.event", %{}, source: "/test")

      result = Jido.AgentServer.call(pid, signal)

      assert {:error, _reason} = result
    end

    test "agent state is retrievable after signal", %{pid: pid} do
      signal = Jido.Signal.new!("document.edit", %{command: "check_state"}, source: "/test")
      {:ok, _agent} = Jido.AgentServer.call(pid, signal)

      {:ok, state} = Jido.AgentServer.state(pid)

      assert state.agent.state.last_command == "check_state"
    end
  end
end
