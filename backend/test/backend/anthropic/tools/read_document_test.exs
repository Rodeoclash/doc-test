defmodule Backend.Anthropic.Tools.ReadDocumentTest do
  use Backend.DataCase

  import Backend.Factory

  alias Backend.Anthropic.Tools.EditDocument
  alias Backend.Anthropic.Tools.ReadDocument

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

    test "returns content after editing" do
      document = insert(:document)

      {:ok, _} =
        EditDocument.execute(%{
          "document_id" => document.id,
          "document" => %{
            "root" => %{
              "children" => [
                %{
                  "type" => "paragraph",
                  "direction" => "ltr",
                  "format" => "",
                  "indent" => 0,
                  "textFormat" => 0,
                  "textStyle" => "",
                  "version" => 1,
                  "children" => [
                    %{
                      "type" => "text",
                      "text" => "hello world",
                      "format" => 0,
                      "detail" => 0,
                      "mode" => "normal",
                      "style" => "",
                      "version" => 1
                    }
                  ]
                }
              ],
              "direction" => "ltr",
              "format" => "",
              "indent" => 0,
              "type" => "root",
              "version" => 1
            }
          }
        })

      assert {:ok, data} = ReadDocument.execute(%{"document_id" => document.id})
      [paragraph] = get_in(data, ["root", "children"])
      [text_node] = paragraph["children"]
      assert text_node["text"] == "hello world"
    end

    test "returns error for a non-existent document" do
      assert {:error, _} = ReadDocument.execute(%{"document_id" => 0})
    end
  end
end
