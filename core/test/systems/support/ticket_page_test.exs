defmodule Systems.Support.TicketPageTest do
  use CoreWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  alias Core.Factories

  describe "require admin role" do
    setup [:login_as_member]

    test "deny access to non-admin", %{conn: conn} do
      ticket = Factories.insert!(:helpdesk_ticket)

      assert {:error, {:redirect, %{to: "/access_denied"}}} =
               live(conn, ~p"/support/ticket/#{ticket.id}")
    end
  end

  describe "helpdesk tickets" do
    setup [:login_as_admin]

    test "show ticket", %{conn: conn} do
      ticket = Factories.insert!(:helpdesk_ticket)
      {:ok, _view, html} = live(conn, ~p"/support/ticket/#{ticket.id}")
      assert html =~ ticket.title
      assert html =~ ticket.description
    end

    test "closing a ticket", %{conn: conn} do
      ticket = Factories.insert!(:helpdesk_ticket)
      {:ok, view, _html} = live(conn, ~p"/support/ticket/#{ticket.id}")

      html =
        view
        |> element("[phx-click=\"close_ticket\"]")
        |> render_click()

      assert {:error, {:live_redirect, %{kind: :push, to: "/support/ticket"}}} = html
    end
  end
end
