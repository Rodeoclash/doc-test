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
end
