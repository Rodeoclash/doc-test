defmodule Backend.Organisations do
  alias Backend.Repo
  alias Backend.Organisations.Organisation

  @doc """
  Gets a single organisation by id. Returns nil if not found.
  """
  @spec get(integer()) :: Organisation.t() | nil
  def get(id), do: Repo.get(Organisation, id)
end
