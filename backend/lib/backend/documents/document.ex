defmodule Backend.Documents.Document do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  schema "documents" do
    field :name, :string
    field :yjs_state, :binary

    belongs_to :organisation, Backend.Organisations.Organisation

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(document, attrs) do
    document
    |> cast(attrs, [:name, :yjs_state])
    |> validate_required([:name])
  end
end
