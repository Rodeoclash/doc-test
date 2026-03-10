defmodule Backend.Agents.Actions.ExecuteEditCommand do
  @moduledoc false
  use Jido.Action,
    name: "execute_edit_command",
    description: "Records an edit command against the document",
    schema: [
      command: [type: :string, required: true]
    ]

  @impl true
  def run(params, _context) do
    {:ok, %{last_command: params.command}}
  end
end
