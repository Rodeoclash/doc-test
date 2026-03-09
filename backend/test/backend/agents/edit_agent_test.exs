defmodule Backend.Agents.EditAgentTest do
  use ExUnit.Case, async: true

  alias Backend.Agents.Actions.ExecuteEditCommand
  alias Backend.Agents.EditAgent

  describe "new/1" do
    test "creates an agent with default state" do
      agent = EditAgent.new(state: %{document_id: 1})
      assert agent.state.document_id == 1
      assert agent.state.status == :idle
      assert agent.state.last_command == nil
    end
  end

  describe "cmd/2" do
    test "executes an edit command and updates state" do
      agent = EditAgent.new(state: %{document_id: 1})

      {agent, _directives} =
        EditAgent.cmd(agent, {ExecuteEditCommand, %{command: "append_hello"}})

      assert agent.state.status == :editing
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
end
