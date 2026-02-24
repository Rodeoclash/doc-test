defmodule BackendWeb.DocumentLive.Show do
  use BackendWeb, :live_view

  alias Backend.Organisations

  @impl true
  def mount(%{"organisation_id" => organisation_id, "id" => _id}, _session, socket) do
    case Organisations.get(organisation_id) do
      nil ->
        raise Ecto.NoResultsError, queryable: Backend.Organisations.Organisation

      organisation ->
        {:ok, assign(socket, :organisation, organisation)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="editor" phx-hook="Editor"></div>
    """
  end
end
