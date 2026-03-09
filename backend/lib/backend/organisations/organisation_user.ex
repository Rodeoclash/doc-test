defmodule Backend.Organisations.OrganisationUser do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  schema "organisation_users" do
    belongs_to :user, Backend.Accounts.User
    belongs_to :organisation, Backend.Organisations.Organisation

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(organisation_user, attrs) do
    organisation_user
    |> cast(attrs, [:user_id, :organisation_id])
    |> validate_required([:user_id, :organisation_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:organisation_id)
    |> unique_constraint([:organisation_id, :user_id])
  end
end
