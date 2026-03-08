defmodule Backend.Documents do
  @moduledoc false
  alias Backend.Documents.Document
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
end
