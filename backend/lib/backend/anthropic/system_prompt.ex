defmodule Backend.Anthropic.SystemPrompt do
  @moduledoc false

  def build(opts) do
    Enum.join([identity(opts), instructions()], "\n\n")
  end

  defp identity(opts) do
    name = Keyword.fetch!(opts, :organisation_name)
    "You are an AI assistant for #{name}."
  end

  defp instructions do
    "Respond using Markdown formatting where appropriate."
  end
end
