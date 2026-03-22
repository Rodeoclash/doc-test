defmodule Backend.Anthropic.SystemPrompt do
  @moduledoc false

  @node_descriptions :backend
                     |> :code.priv_dir()
                     |> Path.join("node_descriptions.md")
                     |> File.read!()

  # To add a new capability (e.g. "evidence_tools"):
  # 1. Add a capability_instructions/1 clause returning its specific instructions
  # 2. Add an append_if line in build/1 for any static content (like @node_descriptions for documents)
  def build(opts) do
    capabilities = Keyword.get(opts, :capabilities, [])

    [identity(opts), base_instructions()]
    |> then(&Enum.reduce(capabilities, &1, fn cap, acc -> acc ++ capability_instructions(cap) end))
    |> append_if("document_tools" in capabilities, @node_descriptions)
    |> Enum.join("\n\n")
  end

  defp identity(opts) do
    name = Keyword.fetch!(opts, :organisation_name)
    "You are an AI assistant for #{name}."
  end

  defp base_instructions do
    "Respond using Markdown formatting where appropriate."
  end

  # Per-capability instructions. Add a new clause for each capability.
  defp capability_instructions("document_tools") do
    [
      """
      You have tools available. Use them to fetch data before answering questions — do not guess at content you haven't read. The user's messages may include context about their current page. Use entity IDs from this context when calling tools.

      When editing a document, you MUST wrap all changes in change nodes so the user can review them:
      - New content must be wrapped in a change node with kind="insert".
      - Content you are removing must be wrapped in a change node with kind="delete".
      - When replacing content, use two change nodes with the same changeId: one kind="delete" wrapping the old content, one kind="insert" wrapping the new content, as adjacent siblings.
      - Each change or group of related changes should have a unique changeId (use a descriptive string like "add-intro" or "rewrite-section-2").
      - Never modify document content without wrapping changes in change nodes. The user must be able to accept or reject every change you make.\
      """
    ]
  end

  defp capability_instructions(_unknown), do: []

  defp append_if(list, true, item), do: list ++ [item]
  defp append_if(list, false, _item), do: list
end
