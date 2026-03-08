defmodule Backend.Organisations.Organisation do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  schema "organisations" do
    field :name, :string

    has_many :documents, Backend.Documents.Document
    has_many :users, Backend.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(organisation, attrs) do
    organisation
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
