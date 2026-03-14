defmodule Backend.Repo.Migrations.CreateConversations do
  use Ecto.Migration

  def change do
    create table(:conversations) do
      add :title, :string
      add :organisation_id, references(:organisations), null: false
      add :user_id, references(:users), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:conversations, [:organisation_id, :user_id])

    create table(:messages) do
      add :role, :string, null: false
      add :content, :text, null: false
      add :context, :map
      add :conversation_id, references(:conversations), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:messages, [:conversation_id])
  end
end
