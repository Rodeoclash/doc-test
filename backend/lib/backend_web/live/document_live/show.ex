defmodule BackendWeb.DocumentLive.Show do
  @moduledoc false
  use BackendWeb, :live_view

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <div class="grid grid-cols-[1fr_20rem] h-full">
      <div
        id="editor"
        phx-hook="Editor"
        data-document-id={@document.id}
        data-username={@current_scope.user.email}
      >
      </div>

      <aside class="border-l border-gray-200 p-4 h-dvh flex flex-col">
        <div class="mt-auto">
          <div class="font-bold mb-2">AI agent chat</div>
          <p class="text-sm text-gray-500">Chat with the AI agent about this document.</p>
        </div>
      </aside>
    </div>
    """
  end
end
