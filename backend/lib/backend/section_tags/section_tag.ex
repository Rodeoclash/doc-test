defmodule Backend.SectionTags.SectionTag do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  schema "section_tags" do
    field :name, :string
    field :description, :string

    belongs_to :organisation, Backend.Organisations.Organisation

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(section_tag, attrs) do
    section_tag
    |> cast(attrs, [:name, :description])
    |> validate_required([:name, :description])
  end
end
