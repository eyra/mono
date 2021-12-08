defmodule Systems.Support.TicketPageTest do
  use CoreWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  alias Core.Factories
  alias Systems.Support

  describe "require admin role" do
    setup [:login_as_member]

    test "deny access to non-admin", %{conn: conn} do
      ticket = Factories.insert!(:helpdesk_ticket)

      assert_error_sent(403, fn ->
        live(conn, Routes.live_path(conn, Support.TicketPage, ticket.id))
      end)
    end
  end

  describe "helpdesk tickets" do
    setup [:login_as_admin]

    test "show ticket", %{conn: conn} do
      ticket = Factories.insert!(:helpdesk_ticket)
      {:ok, _view, html} = live(conn, Routes.live_path(conn, Support.TicketPage, ticket.id))
      assert html =~ ticket.title
      assert html =~ ticket.description
    end

    test "closing a ticket", %{conn: conn} do
      ticket = Factories.insert!(:helpdesk_ticket)
      {:ok, view, _html} = live(conn, Routes.live_path(conn, Support.TicketPage, ticket.id))

      html =
        view
        |> element("[phx-click=\"close_ticket\"]")
        |> render_click()

      assert {:error, {:live_redirect, %{kind: :push, to: "/support/tickets"}}} = html
    end
  end
end
