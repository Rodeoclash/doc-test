defmodule Backend.Anthropic.Tools.ReadDocumentTest do
  use Backend.DataCase

  import Backend.Factory

  alias Backend.Anthropic.Tools.ReadDocument
  alias Backend.Documents.DocServer

  describe "definition/0" do
    test "returns a valid tool definition" do
      defn = ReadDocument.definition()

      assert defn.name == "read_document"
      assert defn.input_schema.required == ["document_id"]
    end
  end

  describe "execute/1" do
    test "returns the Lexical editor state for a valid document" do
      document = insert(:document)

      assert {:ok, data} = ReadDocument.execute(%{"document_id" => document.id})
      assert is_map(data)
      assert Map.has_key?(data, "root")
    end

    test "returns content when document has yjs_state" do
      # Create a document then write content to it via the sidecar
      document = insert(:document)
      {:ok, doc_server} = DocServer.find_or_start(document.id)
      {:ok, _data} = DocServer.execute_command(doc_server, "append_hello")

      assert {:ok, data} = ReadDocument.execute(%{"document_id" => document.id})
      children = get_in(data, ["root", "children"])
      assert length(children) > 0
    end

    test "returns error for a non-existent document" do
      assert {:error, _} = ReadDocument.execute(%{"document_id" => 0})
    end
  end
end
