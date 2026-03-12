defmodule Backend.Repo.Migrations.CreateUsersAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:users) do
      add :email, :citext, null: false
      add :hashed_password, :string
      add :confirmed_at, :utc_datetime
      add :type, :string, null: false, default: "human"

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])

    # Agents cannot have passwords
    create constraint(:users, :agents_cannot_have_passwords,
             check: "type = 'human' OR hashed_password IS NULL"
           )

    create table(:organisation_users) do
      add :user_id, references(:users), null: false
      add :organisation_id, references(:organisations), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:organisation_users, [:organisation_id, :user_id])

    create table(:users_tokens) do
      add :user_id, references(:users), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      add :authenticated_at, :utc_datetime

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:users_tokens, [:user_id])
    create unique_index(:users_tokens, [:context, :token])
  end
end
