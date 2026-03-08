defmodule Backend.Organisations do
  @moduledoc false
  alias Backend.Organisations.Organisation
  alias Backend.Repo

  @doc """
  Gets a single organisation by id. Returns nil if not found.
  """
  @spec get(integer()) :: Organisation.t() | nil
  def get(id), do: Repo.get(Organisation, id)

  @doc """
  Returns the agent user for the given organisation.

  Delegates to `Backend.Accounts.get_agent_for_organisation/1`.
  """
  def get_agent(%Organisation{id: id}), do: Backend.Accounts.get_agent_for_organisation(id)

  def get_agent(organisation_id) when is_integer(organisation_id),
    do: Backend.Accounts.get_agent_for_organisation(organisation_id)
end
