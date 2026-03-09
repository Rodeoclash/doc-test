defmodule Backend.Agents.EditAgent do
  @moduledoc false
  use Jido.Agent,
    name: "edit_agent",
    description: "Drives document editing via the Node.js sidecar",
    schema: [
      document_id: [type: :integer, required: true],
      status: [type: :atom, default: :idle],
      last_command: [type: {:or, [:string, nil]}, default: nil]
    ]
end
