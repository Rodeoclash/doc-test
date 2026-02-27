defmodule Backend.DocumentsTest do
  use Backend.DataCase

  import Backend.Factory

  alias Backend.Documents

  describe "get/1" do
    test "returns the document for a valid id" do
      document = insert(:document)
      assert Documents.get(document.id).id == document.id
    end

    test "returns nil for a non-existent id" do
      assert Documents.get(0) == nil
    end
  end

  describe "update_yjs_state/2" do
    test "persists yjs binary state to the document" do
      document = insert(:document)
      yjs_state = <<0, 1, 2, 3>>

      updated = Documents.update_yjs_state(document.id, yjs_state)

      assert updated.yjs_state == yjs_state
      assert Documents.get(document.id).yjs_state == yjs_state
    end

    test "raises when document does not exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Documents.update_yjs_state(0, <<0>>)
      end
    end
  end
end
