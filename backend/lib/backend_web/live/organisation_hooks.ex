defmodule BackendWeb.OrganisationHooks do
  @moduledoc false
  import Phoenix.Component

  alias Backend.Organisations

  def on_mount(:default, %{"organisation_id" => organisation_id}, _session, socket) do
    case Organisations.get(organisation_id) do
      nil ->
        raise Ecto.NoResultsError, queryable: Backend.Organisations.Organisation

      organisation ->
        {:cont, assign(socket, :organisation, organisation)}
    end
  end
end
