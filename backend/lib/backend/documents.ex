defmodule Backend.Documents do
  alias Backend.Repo
  alias Backend.Documents.Document

  @doc """
  Gets a single organisation by id. Returns nil if not found.
  """
  @spec get(integer()) :: Document.t() | nil
  def get(id), do: Repo.get(Document, id)
end
