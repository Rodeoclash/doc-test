defmodule BackendWeb.DocumentLive.ShowTest do
  use BackendWeb.ConnCase

  import Backend.Factory
  import Phoenix.LiveViewTest

  setup :register_and_log_in_user

  describe "Show" do
    test "renders the editor for a valid document", %{conn: conn, user: user} do
      organisation = insert(:organisation)
      insert(:organisation_user, organisation: organisation, user: user)
      document = insert(:document, organisation: organisation)

      {:ok, _view, html} =
        live(conn, ~p"/organisations/#{organisation.id}/documents/#{document.id}")

      assert html =~ ~s(id="editor")
      assert html =~ ~s(data-document-id="#{document.id}")
      assert html =~ "Send a message to get started."
    end

    test "raises when document does not exist", %{conn: conn} do
      organisation = insert(:organisation)

      assert_raise Ecto.NoResultsError, fn ->
        live(conn, ~p"/organisations/#{organisation.id}/documents/0")
      end
    end

    test "raises when organisation does not exist", %{conn: conn} do
      assert_raise Ecto.NoResultsError, fn ->
        live(conn, ~p"/organisations/0/documents/0")
      end
    end
  end
end
