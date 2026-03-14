defmodule Backend.ConversationsTest do
  use Backend.DataCase

  import Backend.Factory

  alias Backend.Conversations

  describe "create_conversation/3" do
    test "creates a conversation for an organisation and user" do
      org = insert(:organisation)
      user = insert(:user)

      assert {:ok, conversation} = Conversations.create_conversation(org.id, user.id)

      assert conversation.organisation_id == org.id
      assert conversation.user_id == user.id
      assert conversation.title == nil
    end

    test "creates a conversation with a title" do
      org = insert(:organisation)
      user = insert(:user)

      assert {:ok, conversation} = Conversations.create_conversation(org.id, user.id, %{title: "Help with compliance"})

      assert conversation.title == "Help with compliance"
    end
  end

  describe "add_message/2" do
    test "adds a message to a conversation" do
      conversation = insert(:conversation)

      assert {:ok, message} =
               Conversations.add_message(conversation.id, %{
                 role: :user,
                 content: "Hello"
               })

      assert message.conversation_id == conversation.id
      assert message.role == :user
      assert message.content == "Hello"
      assert message.page_context == nil
    end

    test "adds a message with page context" do
      conversation = insert(:conversation)

      assert {:ok, message} =
               Conversations.add_message(conversation.id, %{
                 role: :assistant,
                 content: "I can see you're on the compliance doc.",
                 page_context: %{"type" => "document", "id" => 42}
               })

      assert message.page_context == %{"type" => "document", "id" => 42}
    end

    test "fails without content" do
      conversation = insert(:conversation)

      assert {:error, changeset} =
               Conversations.add_message(conversation.id, %{role: :user})

      assert %{content: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "get_conversation/1" do
    test "returns the conversation with messages preloaded" do
      conversation = insert(:conversation)

      {:ok, _} = Conversations.add_message(conversation.id, %{role: :user, content: "Hello"})
      {:ok, _} = Conversations.add_message(conversation.id, %{role: :assistant, content: "Hi there"})

      result = Conversations.get_conversation(conversation.id)

      assert result.id == conversation.id
      assert length(result.messages) == 2
      assert Enum.map(result.messages, & &1.content) == ["Hello", "Hi there"]
    end

    test "returns messages in chronological order" do
      conversation = insert(:conversation)

      insert(:message, conversation: conversation, content: "First", inserted_at: ~U[2026-03-01 10:00:00Z])
      insert(:message, conversation: conversation, content: "Second", inserted_at: ~U[2026-03-02 10:00:00Z])

      result = Conversations.get_conversation(conversation.id)

      assert Enum.map(result.messages, & &1.content) == ["First", "Second"]
    end

    test "returns nil for non-existent conversation" do
      assert Conversations.get_conversation(0) == nil
    end
  end

  describe "list_conversations/2" do
    test "returns conversations for the given organisation and user" do
      org = insert(:organisation)
      user = insert(:user)

      insert(:conversation, organisation: org, user: user)
      insert(:conversation, organisation: org, user: user)

      assert length(Conversations.list_conversations(org.id, user.id)) == 2
    end

    test "does not return conversations from other users or organisations" do
      org = insert(:organisation)
      user = insert(:user)
      other_user = insert(:user)
      other_org = insert(:organisation)

      insert(:conversation, organisation: org, user: user)
      insert(:conversation, organisation: org, user: other_user)
      insert(:conversation, organisation: other_org, user: user)

      assert length(Conversations.list_conversations(org.id, user.id)) == 1
    end

    test "orders by most recently updated first" do
      org = insert(:organisation)
      user = insert(:user)

      older = insert(:conversation, organisation: org, user: user, inserted_at: ~U[2026-03-01 10:00:00Z])
      newer = insert(:conversation, organisation: org, user: user, inserted_at: ~U[2026-03-02 10:00:00Z])

      conversations = Conversations.list_conversations(org.id, user.id)

      assert Enum.map(conversations, & &1.id) == [newer.id, older.id]
    end

    test "returns empty list when no conversations exist" do
      org = insert(:organisation)
      user = insert(:user)

      assert Conversations.list_conversations(org.id, user.id) == []
    end
  end
end
