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

  describe "publish_document/2" do
    test "publishes a draft document and creates a version snapshot" do
      user = insert(:user)
      document = insert(:document, yjs_state: <<1, 2, 3>>, major_version: 1, minor_version: 0)

      assert {:ok, published} = Documents.publish_document(document.id, user.id)

      assert published.status == :published
      assert published.major_version == 1
      assert published.minor_version == 0

      version = Repo.get_by!(Documents.DocumentVersion, document_id: document.id)
      assert version.yjs_state == <<1, 2, 3>>
      assert version.major_version == 1
      assert version.minor_version == 0
      assert version.published_by_user_id == user.id
      assert version.published_at
    end

    test "returns error when document is already published" do
      user = insert(:user)
      document = insert(:document, status: :published)

      assert {:error, :not_draft} = Documents.publish_document(document.id, user.id)
    end

    test "returns error when document has no content" do
      user = insert(:user)
      document = insert(:document, yjs_state: nil)

      assert {:error, changeset} = Documents.publish_document(document.id, user.id)
      assert %{yjs_state: ["can't be blank"]} = errors_on(changeset)
    end
  end
end
