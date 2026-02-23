defmodule BackendWeb.DocumentLive.Show do
  use BackendWeb, :live_view

  @impl true
  def mount(%{"organisation_id" => _organisation_id, "id" => _id}, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="editor" phx-hook="Editor"></div>
    """
  end
end
