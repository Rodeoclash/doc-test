defmodule Backend.Conversations do
  @moduledoc false

  import Ecto.Query

  alias Backend.Conversations.Conversation
  alias Backend.Conversations.Message
  alias Backend.Conversations.MessageFormat
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

  def get_conversation(id) do
    Conversation
    |> Repo.get(id)
    |> Repo.preload(messages: from(m in Message, order_by: m.inserted_at))
  end

  def add_message(conversation_id, attrs) do
    %Message{}
    |> Message.changeset(Map.put(attrs, :conversation_id, conversation_id))
    |> Repo.insert()
  end

  def messages_for_api(conversation_id) do
    case get_conversation(conversation_id) do
      nil ->
        {:error, :not_found}

      conversation ->
        messages =
          Enum.map(conversation.messages, fn message ->
            content = MessageFormat.encode(message.content, message.page_context)
            %{role: to_string(message.role), content: content}
          end)

        {:ok, messages}
    end
  end
end
