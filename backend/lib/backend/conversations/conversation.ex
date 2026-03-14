defmodule Backend.Conversations.Conversation do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  schema "conversations" do
    field :title, :string

    belongs_to :organisation, Backend.Organisations.Organisation
    belongs_to :user, Backend.Accounts.User
    has_many :messages, Backend.Conversations.Message

    timestamps(type: :utc_datetime)
  end

  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:title, :organisation_id, :user_id])
    |> validate_required([:organisation_id, :user_id])
  end
end
