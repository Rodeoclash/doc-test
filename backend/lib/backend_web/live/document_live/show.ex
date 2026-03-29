defmodule BackendWeb.DocumentLive.Show do
  @moduledoc false
  use BackendWeb, :live_view

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <div id="document-layout" class="flex h-dvh" phx-hook="ResizablePanel">
      <div class="flex-1 min-w-0 min-h-0 flex flex-col bg-gray-50">
        <div class="mx-auto w-full max-w-4xl px-8 pt-6 shrink-0">
          <div class="bg-white border border-gray-200 rounded-t-lg px-4 py-2 flex items-center gap-1 text-gray-400">
            <.icon name="hero-bold" class="size-5" />
            <.icon name="hero-italic" class="size-5" />
            <.icon name="hero-underline" class="size-5" />
            <.icon name="hero-strikethrough" class="size-5" />
            <div class="w-px h-5 bg-gray-200 mx-1"></div>
            <.icon name="hero-list-bullet" class="size-5" />
            <.icon name="hero-numbered-list" class="size-5" />
            <div class="w-px h-5 bg-gray-200 mx-1"></div>
            <.icon name="hero-link" class="size-5" />
          </div>
        </div>
        <div class="flex-1 min-h-0 overflow-y-auto">
          <div class="mx-auto w-full max-w-4xl px-8 pb-6">
            <div
              id="editor"
              class="bg-white border-x border-b border-gray-200 rounded-b-lg p-8"
              phx-hook="Editor"
              data-document-id={@document.id}
              data-username={@current_scope.user.email}
            >
            </div>
          </div>
        </div>
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
