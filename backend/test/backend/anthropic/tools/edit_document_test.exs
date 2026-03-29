defmodule Backend.Anthropic.Tools.EditDocumentTest do
  use Backend.DataCase

  import Backend.Factory

  alias Backend.Anthropic.Tools.EditDocument

  setup do
    on_exit(fn ->
      Backend.DocSupervisor
      |> DynamicSupervisor.which_children()
      |> Enum.each(fn {_, pid, _, _} ->
        DynamicSupervisor.terminate_child(Backend.DocSupervisor, pid)
      end)
    end)
  end

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

    test "returns error for unknown node type" do
      document = insert(:document)

      invalid_state = %{
        "root" => %{
          "children" => [
            %{
              "type" => "nonexistent_node",
              "direction" => "ltr",
              "format" => "",
              "indent" => 0,
              "version" => 1,
              "children" => []
            }
          ],
          "direction" => "ltr",
          "format" => "",
          "indent" => 0,
          "type" => "root",
          "version" => 1
        }
      }

      assert {:error, reason} =
               EditDocument.execute(%{
                 "document_id" => document.id,
                 "document" => invalid_state
               })

      assert reason =~ "nonexistent_node"
    end

    test "returns error for invalid JSON structure" do
      document = insert(:document)

      assert {:error, reason} =
               EditDocument.execute(%{
                 "document_id" => document.id,
                 "document" => %{"not_a_valid" => "editor_state"}
               })

      assert reason =~ "parseEditorState failed"
    end

    test "returns error for a non-existent document" do
      assert {:error, :document_not_found} =
               EditDocument.execute(%{
                 "document_id" => 0,
                 "document" => @sample_state
               })
    end
  end
end
