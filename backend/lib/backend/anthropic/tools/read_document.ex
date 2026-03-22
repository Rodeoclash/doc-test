defmodule Backend.Anthropic.Tools.ReadDocument do
  @moduledoc false

  alias Backend.Documents.DocServer

  def definition do
    %{
      name: "read_document",
      description: "Read the content of a document. Returns the Lexical editor state as JSON.",
      input_schema: %{
        type: "object",
        properties: %{
          document_id: %{type: "integer", description: "The ID of the document to read."}
        },
        required: ["document_id"]
      }
    }
  end

  def execute(%{"document_id" => document_id}) do
    with {:ok, doc_server} <- DocServer.find_or_start(document_id) do
      DocServer.execute_query(doc_server, "read_document")
    end
  end
end
