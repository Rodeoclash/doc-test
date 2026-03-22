defmodule Backend.Anthropic.Tools do
  @moduledoc false

  # To add a new capability (e.g. "evidence_tools"):
  # 1. Create tool modules under Backend.Anthropic.Tools.*
  # 2. Add an entry to @tool_groups with the capability key and tool modules
  @tool_groups %{
    "document_tools" => [
      Backend.Anthropic.Tools.ReadDocument,
      Backend.Anthropic.Tools.EditDocument
    ]
  }

  @all_tools @tool_groups |> Map.values() |> List.flatten() |> Enum.uniq()

  def definitions(capabilities) do
    capabilities
    |> Enum.flat_map(fn cap -> Map.get(@tool_groups, cap, []) end)
    |> Enum.uniq()
    |> Enum.map(& &1.definition())
  end

  def execute(name, input) do
    case Enum.find(@all_tools, fn t -> t.definition().name == name end) do
      nil -> {:error, "unknown tool: #{name}"}
      tool -> tool.execute(input)
    end
  end
end
