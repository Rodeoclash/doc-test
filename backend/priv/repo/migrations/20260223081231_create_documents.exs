defmodule Backend.Repo.Migrations.CreateDocuments do
  use Ecto.Migration

  def change do
    create table(:documents) do
      add :name, :string
      add :yjs_state, :binary
      add :organisation_id, references(:organisations), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:documents, [:organisation_id])
  end
end
