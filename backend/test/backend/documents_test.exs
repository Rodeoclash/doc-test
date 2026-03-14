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

  describe "start_new_draft/2" do
    test "transitions a published document to draft with a new version" do
      document = insert(:document, status: :published, major_version: 1, minor_version: 0)

      assert {:ok, draft} = Documents.start_new_draft(document.id, %{major_version: 1, minor_version: 1})

      assert draft.status == :draft
      assert draft.major_version == 1
      assert draft.minor_version == 1
    end

    test "returns error when document is already a draft" do
      document = insert(:document, status: :draft)

      assert {:error, :not_published} = Documents.start_new_draft(document.id, %{major_version: 1, minor_version: 0})
    end
  end

  describe "list_versions/1" do
    test "returns versions in descending order by published_at" do
      user = insert(:user)
      document = insert(:document)

      insert(:document_version,
        document: document,
        published_by_user: user,
        minor_version: 0,
        published_at: ~U[2026-03-01 10:00:00Z]
      )

      insert(:document_version,
        document: document,
        published_by_user: user,
        minor_version: 1,
        published_at: ~U[2026-03-02 10:00:00Z]
      )

      versions = Documents.list_versions(document.id)

      assert length(versions) == 2
      assert Enum.at(versions, 0).minor_version == 1
      assert Enum.at(versions, 1).minor_version == 0
    end

    test "returns empty list when no versions exist" do
      document = insert(:document)

      assert Documents.list_versions(document.id) == []
    end
  end

  describe "get_version/3" do
    test "returns the version matching document, major, and minor" do
      user = insert(:user)
      document = insert(:document, yjs_state: <<1>>)

      {:ok, _} = Documents.publish_document(document.id, user.id)

      version = Documents.get_version(document.id, 0, 0)

      assert version.document_id == document.id
      assert version.major_version == 0
      assert version.minor_version == 0
    end

    test "returns nil when version does not exist" do
      document = insert(:document)

      assert Documents.get_version(document.id, 99, 99) == nil
    end
  end
end
