defmodule CoreWeb.Admin.SupportTest do
  use CoreWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  alias Core.Factories
  alias CoreWeb.Admin

  describe "require admin role" do
    setup [:login_as_member]

    test "deny access to non-admin", %{conn: conn} do
      {:ok, _view, html} = live(conn, Routes.live_path(conn, Admin.Support))
      assert html =~ "Access Denied"
    end
  end

  describe "helpdesk tickets" do
    setup [:login_as_admin]

    test "list open tickets", %{conn: conn} do
      ticket = Factories.insert!(:helpdesk_ticket)
      {:ok, _view, html} = live(conn, Routes.live_path(conn, Admin.Support))
      assert html =~ ticket.title
    end

    test "closed tickets are not visible", %{conn: conn} do
      ticket =
        Factories.insert!(:helpdesk_ticket, %{
          completed_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })

      {:ok, _view, html} = live(conn, Routes.live_path(conn, Admin.Support))
      refute html =~ ticket.title
    end
  end
end
