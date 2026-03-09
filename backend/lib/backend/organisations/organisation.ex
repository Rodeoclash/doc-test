defmodule Backend.Organisations.Organisation do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  schema "organisations" do
    field :name, :string

    has_many :documents, Backend.Documents.Document
    has_many :organisation_users, Backend.Organisations.OrganisationUser
    has_many :users, through: [:organisation_users, :user]

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(organisation, attrs) do
    organisation
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
