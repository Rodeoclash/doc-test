defmodule BackendWeb.DocumentHooks do
  @moduledoc false
  import Phoenix.Component

  alias Backend.Documents

  def on_mount(:default, %{"id" => id}, _session, socket) do
    case Documents.get(id) do
      nil -> raise Ecto.NoResultsError, queryable: Backend.Documents.Document
      document -> {:cont, assign(socket, :document, document)}
    end
  end
end
