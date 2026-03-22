defmodule Backend.Anthropic.ToolsTest do
  use ExUnit.Case, async: true

  alias Backend.Anthropic.Tools

  describe "definitions/1" do
    test "returns document tools for document_tools capability" do
      names =
        ["document_tools"]
        |> Tools.definitions()
        |> Enum.map(& &1.name)

      assert names == ["read_document", "edit_document"]
    end

    test "returns empty list for no capabilities" do
      assert Tools.definitions([]) == []
    end

    test "returns empty list for unknown capability" do
      assert Tools.definitions(["nonexistent"]) == []
    end
  end

  describe "execute/2" do
    test "returns error for unknown tool" do
      assert {:error, "unknown tool: nonexistent"} = Tools.execute("nonexistent", %{})
    end
  end
end
