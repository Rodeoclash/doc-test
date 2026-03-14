defmodule Backend.Documents.Document do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  schema "documents" do
    field :name, :string
    field :yjs_state, :binary
    field :status, Ecto.Enum, values: [:draft, :published], default: :draft
    field :major_version, :integer, default: 0
    field :minor_version, :integer, default: 0

    belongs_to :organisation, Backend.Organisations.Organisation
    has_many :versions, Backend.Documents.DocumentVersion

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(document, attrs) do
    document
    |> cast(attrs, [:name, :yjs_state])
    |> validate_required([:name])
  end

  def publish_changeset(document) do
    change(document, status: :published)
  end

  def draft_changeset(document, attrs) do
    document
    |> cast(attrs, [:major_version, :minor_version])
    |> validate_required([:major_version, :minor_version])
    |> validate_number(:major_version, greater_than_or_equal_to: 0)
    |> validate_number(:minor_version, greater_than_or_equal_to: 0)
    |> put_change(:status, :draft)
  end
end
