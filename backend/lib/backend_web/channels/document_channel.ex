defmodule BackendWeb.DocumentChannel do
  @moduledoc false
  use Phoenix.Channel

  alias Backend.Documents.DocServer

  require Logger

  @impl true
  def join("document:" <> document_id, _params, socket) do
    document_id = String.to_integer(document_id)

    case DocServer.find_or_start(document_id) do
      {:ok, doc_server} ->
        Logger.info("DocumentChannel joined for document #{document_id}")

        socket =
          socket
          |> assign(:document_id, document_id)
          |> assign(:doc_server, doc_server)

        {:ok, socket}

      {:error, reason} ->
        Logger.error("DocumentChannel failed to join document #{document_id}: #{inspect(reason)}")
        {:error, %{reason: "failed to start document server"}}
    end
  end

  @impl true
  def handle_in("yjs", %{"data" => data}, socket) do
    message = Base.decode64!(data)

    case DocServer.process_message_v1(socket.assigns.doc_server, message, self()) do
      :ok ->
        {:noreply, socket}

      {:ok, replies} ->
        for reply <- replies do
          push(socket, "yjs", %{"data" => Base.encode64(reply)})
        end

        {:noreply, socket}

      {:error, reason} ->
        Logger.error("Failed to process yjs message: #{inspect(reason)}")
        {:noreply, socket}
    end
  end
end
