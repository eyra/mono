defmodule CoreWeb.Admin.TicketTest do
  use CoreWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  alias Core.Factories
  alias CoreWeb.Admin

  describe "require admin role" do
    setup [:login_as_member]

    test "deny access to non-admin", %{conn: conn} do
      ticket = Factories.insert!(:helpdesk_ticket)

      assert_error_sent(403, fn ->
        live(conn, Routes.live_path(conn, Admin.Ticket, ticket.id))
      end)
    end
  end

  describe "helpdesk tickets" do
    setup [:login_as_admin]

    test "show ticket", %{conn: conn} do
      ticket = Factories.insert!(:helpdesk_ticket)
      {:ok, _view, html} = live(conn, Routes.live_path(conn, Admin.Ticket, ticket.id))
      assert html =~ ticket.title
      assert html =~ ticket.description
    end

    test "closing a ticket", %{conn: conn} do
      ticket = Factories.insert!(:helpdesk_ticket)
      {:ok, view, _html} = live(conn, Routes.live_path(conn, Admin.Ticket, ticket.id))

      html =
        view
        |> element("[phx-click=\"close_ticket\"]")
        |> render_click()

      assert html =~ "Close ticket?"

      redirect =
        view
        |> element("[phx-click=\"close_confirm\"]")
        |> render_click()

      assert redirect == {:error, {:live_redirect, %{kind: :push, to: "/admin/support"}}}
    end

    test "cancel closing a ticket", %{conn: conn} do
      ticket = Factories.insert!(:helpdesk_ticket)
      {:ok, view, _html} = live(conn, Routes.live_path(conn, Admin.Ticket, ticket.id))

      html =
        view
        |> element("[phx-click=\"close_ticket\"]")
        |> render_click()

      assert html =~ "Close ticket?"

      html =
        view
        |> element("[phx-click=\"close_cancel\"]")
        |> render_click()

      assert html =~ ticket.title
    end
  end
end
