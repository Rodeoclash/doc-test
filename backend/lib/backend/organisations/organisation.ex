defmodule Backend.Organisations.Organisation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "organisations" do
    field :name, :string

    has_many :section_tags, Backend.SectionTags.SectionTag
    has_many :documents, Backend.Documents.Document

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(organisation, attrs) do
    organisation
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
