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
    """
    Respond using Markdown formatting where appropriate.

    You have tools available. Use them to fetch data before answering questions — do not guess at content you haven't read. The user's messages may include context about their current page. Use entity IDs from this context when calling tools.\
    """
  end
end
