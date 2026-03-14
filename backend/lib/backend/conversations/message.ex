defmodule Backend.Conversations.Message do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  schema "messages" do
    field :role, Ecto.Enum, values: [:user, :assistant]
    field :content, :string
    field :page_context, :map

    belongs_to :conversation, Backend.Conversations.Conversation

    timestamps(type: :utc_datetime)
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:role, :content, :page_context, :conversation_id])
    |> validate_required([:role, :content, :conversation_id])
  end
end
