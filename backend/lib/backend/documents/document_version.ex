defmodule Backend.Documents.DocumentVersion do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  schema "document_versions" do
    field :yjs_state, :binary
    field :major_version, :integer
    field :minor_version, :integer
    field :published_at, :utc_datetime

    belongs_to :document, Backend.Documents.Document
    belongs_to :published_by_user, Backend.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(version, attrs) do
    version
    |> cast(attrs, [:yjs_state, :major_version, :minor_version, :published_at, :document_id, :published_by_user_id])
    |> validate_required([:yjs_state, :major_version, :minor_version, :published_at, :document_id, :published_by_user_id])
    |> validate_number(:major_version, greater_than_or_equal_to: 0)
    |> validate_number(:minor_version, greater_than_or_equal_to: 0)
    |> unique_constraint([:document_id, :major_version, :minor_version])
    |> foreign_key_constraint(:document_id)
  end
end
