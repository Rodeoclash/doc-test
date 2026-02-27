defmodule BackendWeb.DocumentLive.Show do
  use BackendWeb, :live_view

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <div id="editor" phx-hook="Editor" data-document-id={@document.id}></div>
    """
  end
end
