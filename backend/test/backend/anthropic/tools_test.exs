defmodule Backend.Anthropic.ToolsTest do
  use ExUnit.Case, async: true

  alias Backend.Anthropic.Tools

  describe "definitions/0" do
    test "returns a list of tool definitions" do
      definitions = Tools.definitions()

      assert is_list(definitions)
      assert Enum.any?(definitions, &(&1.name == "read_document"))
    end
  end

  describe "execute/2" do
    test "returns error for unknown tool" do
      assert {:error, "unknown tool: nonexistent"} = Tools.execute("nonexistent", %{})
    end
  end
end
