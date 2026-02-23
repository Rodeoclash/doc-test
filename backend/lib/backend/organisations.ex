defmodule Backend.Organisations do
  alias Backend.Repo
  alias Backend.Organisations.Organisation

  @doc """
  Gets a single organisation by id. Returns nil if not found.
  """
  def get(id), do: Repo.get(Organisation, id)
end
