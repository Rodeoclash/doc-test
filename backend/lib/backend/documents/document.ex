defmodule Backend.Documents.Document do
  use Ecto.Schema
  import Ecto.Changeset

  schema "documents" do
    field :name, :string
    field :content, :map

    belongs_to :organisation, Backend.Organisations.Organisation

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(document, attrs) do
    document
    |> cast(attrs, [:name, :content])
    |> validate_required([:name])
  end
end
