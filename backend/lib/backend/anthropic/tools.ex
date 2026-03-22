defmodule Backend.Anthropic.Tools do
  @moduledoc false

  @tools [
    Backend.Anthropic.Tools.ReadDocument,
    Backend.Anthropic.Tools.EditDocument
  ]

  def definitions, do: Enum.map(@tools, & &1.definition())

  def execute(name, input) do
    case Enum.find(@tools, fn t -> t.definition().name == name end) do
      nil -> {:error, "unknown tool: #{name}"}
      tool -> tool.execute(input)
    end
  end
end
