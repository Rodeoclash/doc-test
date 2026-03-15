defmodule BackendWeb.ChatLive.Sidebar do
  @moduledoc false
  use BackendWeb, :live_view

  alias Backend.Conversations
  alias Backend.OrganisationUsers

  @impl true
  def mount(_params, session, socket) do
    organisation_user = OrganisationUsers.get(session["organisation_user_id"])
    context = session["context"]

    conversation =
      load_or_create_conversation(organisation_user.organisation_id, organisation_user.user_id)

    {:ok,
     assign(socket,
       organisation_user: organisation_user,
       context: context,
       conversation: conversation
     )}
  end

  @impl true
  def handle_event("send_message", %{"content" => content}, socket) when content != "" do
    {:ok, _message} =
      Conversations.add_message(socket.assigns.conversation.id, %{
        role: :user,
        content: content,
        context: socket.assigns.context
      })

    {:noreply, reload_conversation(socket)}
  end

  def handle_event("send_message", _params, socket), do: {:noreply, socket}

  defp load_or_create_conversation(organisation_id, user_id) do
    case Conversations.list_conversations(organisation_id, user_id) do
      [conversation | _] ->
        Conversations.get_conversation(conversation.id)

      [] ->
        {:ok, conversation} = Conversations.create_conversation(organisation_id, user_id)
        Conversations.get_conversation(conversation.id)
    end
  end

  defp reload_conversation(socket) do
    conversation = Conversations.get_conversation(socket.assigns.conversation.id)
    assign(socket, :conversation, conversation)
  end
end
