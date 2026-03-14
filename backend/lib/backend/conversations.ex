defmodule Backend.Conversations do
  @moduledoc false

  import Ecto.Query

  alias Backend.Conversations.Conversation
  alias Backend.Conversations.Message
  alias Backend.Repo

  def create_conversation(organisation_id, user_id, attrs \\ %{}) do
    %Conversation{}
    |> Conversation.changeset(Map.merge(attrs, %{organisation_id: organisation_id, user_id: user_id}))
    |> Repo.insert()
  end

  def list_conversations(organisation_id, user_id) do
    Conversation
    |> where(organisation_id: ^organisation_id, user_id: ^user_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  def add_message(conversation_id, attrs) do
    %Message{}
    |> Message.changeset(Map.put(attrs, :conversation_id, conversation_id))
    |> Repo.insert()
  end
end
