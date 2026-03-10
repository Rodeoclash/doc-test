defmodule Backend.Agents.EditAgent do
  @moduledoc false
  use Jido.Agent,
    name: "edit_agent",
    description: "Drives document editing via the Node.js sidecar",
    schema: [
      document_id: [type: :integer, required: true],
      last_command: [type: {:or, [:string, nil]}, default: nil]
    ],
    signal_routes: [
      {"document.edit", Backend.Agents.Actions.ExecuteEditCommand}
    ]
end
