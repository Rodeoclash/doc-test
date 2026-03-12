defmodule Backend.Repo.Migrations.CreateOrganisations do
  use Ecto.Migration

  def change do
    create table(:organisations) do
      add :name, :string, null: false

      timestamps(type: :utc_datetime)
    end
  end
end
