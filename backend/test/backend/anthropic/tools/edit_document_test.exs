defmodule Backend.Anthropic.Tools.EditDocumentTest do
  use Backend.DataCase

  import Backend.Factory

  alias Backend.Anthropic.Tools.EditDocument
  alias Backend.Anthropic.Tools.ReadDocument

  @sample_state %{
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

  describe "definition/0" do
    test "returns a valid tool definition" do
      defn = EditDocument.definition()

      assert defn.name == "edit_document"
      assert defn.input_schema.required == ["document_id", "document"]
    end
  end

  describe "execute/1" do
    test "applies a document state and returns the result" do
      document = insert(:document)

      assert {:ok, data} =
               EditDocument.execute(%{
                 "document_id" => document.id,
                 "document" => @sample_state
               })

      assert data |> get_in(["root", "children"]) |> length() > 0
    end

    test "content is readable after editing" do
      document = insert(:document)

      {:ok, _} =
        EditDocument.execute(%{
          "document_id" => document.id,
          "document" => @sample_state
        })

      {:ok, data} = ReadDocument.execute(%{"document_id" => document.id})
      children = get_in(data, ["root", "children"])
      assert length(children) == 1

      [paragraph] = children
      [text_node] = paragraph["children"]
      assert text_node["text"] == "hello world"
    end

    test "returns error for a non-existent document" do
      assert {:error, _} =
               EditDocument.execute(%{
                 "document_id" => 0,
                 "document" => @sample_state
               })
    end
  end
end
