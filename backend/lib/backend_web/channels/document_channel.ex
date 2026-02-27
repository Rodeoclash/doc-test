defmodule BackendWeb.DocumentChannel do
  @moduledoc false
  use Phoenix.Channel

  require Logger

  @impl true
  def join("document:" <> document_id, _params, socket) do
    Logger.info("DocumentChannel joined for document #{document_id}")
    send(self(), :after_join)
    {:ok, assign(socket, :document_id, document_id)}
  end

  @impl true
  def handle_info(:after_join, socket) do
    push(socket, "hello", %{message: "Connected to document #{socket.assigns.document_id}"})
    {:noreply, socket}
  end
end
