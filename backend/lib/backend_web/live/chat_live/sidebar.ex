defmodule BackendWeb.ChatLive.Sidebar do
  @moduledoc false
  use BackendWeb, :live_view

  alias Backend.Anthropic
  alias Backend.Conversations
  alias Backend.OrganisationUsers
  alias BackendWeb.Helpers.Markdown

  require Logger

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
       conversation: conversation,
       loading: false,
       error: nil
     )}
  end

  @impl true
  def handle_event("send_message", %{"content" => content}, socket) when content != "" do
    conversation_id = socket.assigns.conversation.id

    {:ok, _message} =
      Conversations.add_message(conversation_id, %{role: :user, content: content})

    Task.async(fn ->
      {:ok, api_messages} = Conversations.messages_for_api(conversation_id)
      Anthropic.chat(api_messages)
    end)

    {:noreply, socket |> assign(loading: true, error: nil) |> reload_conversation()}
  end

  def handle_event("send_message", _params, socket), do: {:noreply, socket}

  @impl true
  def handle_info({ref, {:ok, response}}, socket) do
    Process.demonitor(ref, [:flush])

    text =
      response.content
      |> Enum.filter(&(&1.type == :text))
      |> Enum.map_join("\n", & &1.text)

    Conversations.add_message(socket.assigns.conversation.id, %{
      role: :assistant,
      content: text
    })

    {:noreply, socket |> assign(:loading, false) |> reload_conversation()}
  end

  def handle_info({ref, {:error, reason}}, socket) do
    Process.demonitor(ref, [:flush])
    Logger.error("Claude API error: #{inspect(reason)}")
    {:noreply, assign(socket, loading: false, error: "Something went wrong. Please try again.")}
  end

  def handle_info({:DOWN, _ref, :process, _pid, reason}, socket) do
    Logger.error("Chat task crashed: #{inspect(reason)}")
    {:noreply, assign(socket, loading: false, error: "Something went wrong. Please try again.")}
  end

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
