defmodule Backend.Repo.Migrations.CreateDocuments do
  use Ecto.Migration

  def change do
    create table(:documents) do
      add :name, :string
      add :content, :map
      add :organisation_id, references(:organisations, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:documents, [:organisation_id])
  end
end
