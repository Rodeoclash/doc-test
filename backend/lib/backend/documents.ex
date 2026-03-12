defmodule Backend.Documents do
  @moduledoc false
  import Ecto.Query

  alias Backend.Documents.Document
  alias Backend.Documents.DocumentVersion
  alias Backend.Repo

  @doc """
  Returns the PubSub topic for a document.
  """
  def topic(document_id), do: "document:#{document_id}"

  @doc """
  Gets a single document by id. Returns nil if not found.
  """
  @spec get(integer()) :: Document.t() | nil
  def get(id), do: Repo.get(Document, id)

  @doc """
  Persists the Yjs binary state for a document.
  """
  def update_yjs_state(document_id, yjs_state) do
    Document
    |> Repo.get!(document_id)
    |> Ecto.Changeset.change(%{yjs_state: yjs_state})
    |> Repo.update!()
  end

  @doc """
  Publishes a draft document. Snapshots the current yjs_state and version
  into a new DocumentVersion and sets the document status to published.

  Returns `{:error, :not_draft}` if the document is already published.
  """
  def publish_document(document_id, published_by_user_id) do
    Repo.transaction(fn ->
      document =
        Document
        |> where(id: ^document_id)
        |> lock("FOR UPDATE")
        |> Repo.one!()

      if document.status != :draft do
        Repo.rollback(:not_draft)
      end

      version_changeset =
        DocumentVersion.changeset(%DocumentVersion{}, %{
          document_id: document.id,
          yjs_state: document.yjs_state,
          major_version: document.major_version,
          minor_version: document.minor_version,
          published_at: DateTime.utc_now(:second),
          published_by_user_id: published_by_user_id
        })

      case Repo.insert(version_changeset) do
        {:ok, _version} ->
          {:ok, document} =
            document
            |> Document.publish_changeset()
            |> Repo.update()

          document

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end
end
