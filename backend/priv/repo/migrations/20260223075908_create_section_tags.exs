defmodule Backend.Repo.Migrations.CreateSectionTags do
  use Ecto.Migration

  def change do
    create table(:section_tags) do
      add :name, :string
      add :description, :text
      add :organisation_id, references(:organisations)

      timestamps(type: :utc_datetime)
    end

    create index(:section_tags, [:organisation_id])
  end
end
