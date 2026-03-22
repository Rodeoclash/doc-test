defmodule Backend.Anthropic.Tools.EditDocument do
  @moduledoc false

  alias Backend.Documents.DocServer

  def definition do
    %{
      name: "edit_document",
      description:
        "Apply a modified Lexical editor state to a document. The data must be a complete Lexical editor state JSON object with a root node containing the full document content.",
      input_schema: %{
        type: "object",
        properties: %{
          document_id: %{type: "integer", description: "The ID of the document to edit."},
          document: %{type: "object", description: "The complete Lexical editor state JSON."}
        },
        required: ["document_id", "document"]
      }
    }
  end

  def execute(%{"document_id" => document_id, "document" => document}) do
    with {:ok, doc_server} <- DocServer.find_or_start(document_id) do
      DocServer.execute_command(doc_server, "apply_document", document)
    end
  end
end
