defmodule Backend.Repo.Migrations.CreateDocumentVersions do
  use Ecto.Migration

  def change do
    create table(:document_versions) do
      add :document_id, references(:documents), null: false
      add :yjs_state, :binary, null: false
      add :major_version, :integer, null: false
      add :minor_version, :integer, null: false
      add :published_at, :utc_datetime, null: false
      add :published_by_user_id, references(:users)

      timestamps(type: :utc_datetime)
    end

    create index(:document_versions, [:document_id])
    create unique_index(:document_versions, [:document_id, :major_version, :minor_version])
  end
end
