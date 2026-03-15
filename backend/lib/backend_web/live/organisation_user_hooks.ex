defmodule BackendWeb.OrganisationUserHooks do
  @moduledoc false
  import Phoenix.Component

  alias Backend.OrganisationUsers

  def on_mount(:default, %{"organisation_id" => organisation_id}, _session, socket) do
    user_id = socket.assigns.current_scope.user.id

    case OrganisationUsers.get_by_organisation_and_user(organisation_id, user_id) do
      nil ->
        raise Ecto.NoResultsError, queryable: Backend.Organisations.OrganisationUser

      organisation_user ->
        {:cont, assign(socket, :organisation_user, organisation_user)}
    end
  end
end
