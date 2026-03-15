defmodule Backend.OrganisationUsers do
  @moduledoc false

  import Ecto.Query

  alias Backend.Organisations.OrganisationUser
  alias Backend.Repo

  def get(id) do
    OrganisationUser
    |> Repo.get(id)
    |> Repo.preload([:organisation, :user])
  end

  def get_by_organisation_and_user(organisation_id, user_id) do
    OrganisationUser
    |> where(organisation_id: ^organisation_id, user_id: ^user_id)
    |> Repo.one()
    |> Repo.preload([:organisation, :user])
  end
end
