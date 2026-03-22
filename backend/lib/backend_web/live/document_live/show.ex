defmodule BackendWeb.DocumentLive.Show do
  @moduledoc false
  use BackendWeb, :live_view

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <div id="document-layout" class="flex h-full" phx-hook="ResizablePanel">
      <div
        id="editor"
        class="flex-1 min-w-0"
        phx-hook="Editor"
        data-document-id={@document.id}
        data-username={@current_scope.user.email}
      >
      </div>

      <div data-resize-panel>
        {live_render(@socket, BackendWeb.ChatLive.Sidebar,
          id: "chat-sidebar",
          session: %{
            "organisation_user_id" => @organisation_user.id,
            "context" => %{
              "type" => "document",
              "id" => to_string(@document.id),
              "title" => @document.name,
              "action" => "editing",
              "capabilities" => ["document_tools"]
            }
          }
        )}
      </div>
    </div>
    """
  end
end
