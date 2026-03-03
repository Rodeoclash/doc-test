defmodule BackendWeb.DocumentLive.Show do
  @moduledoc false
  use BackendWeb, :live_view

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id="editor"
      phx-hook="Editor"
      data-document-id={@document.id}
      data-username={@current_scope.user.email}
    >
    </div>
    """
  end
end
