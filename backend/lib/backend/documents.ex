defmodule Backend.Documents do
  @moduledoc false
  alias Backend.Documents.Document
  alias Backend.Repo

  @doc """
  Gets a single organisation by id. Returns nil if not found.
  """
  @spec get(integer()) :: Document.t() | nil
  def get(id), do: Repo.get(Document, id)
end
