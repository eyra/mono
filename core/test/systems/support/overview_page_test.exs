defmodule Systems.Support.OverviewPageTest do
  use CoreWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  alias Core.Factories
  alias Systems.Support

  describe "require admin role" do
    setup [:login_as_member]

    test "deny access to non-admin", %{conn: conn} do
      assert_error_sent(403, fn ->
        live(conn, Routes.live_path(conn, Support.OverviewPage))
      end)
    end
  end

  describe "helpdesk tickets" do
    setup [:login_as_admin]

    test "list open tickets", %{conn: conn} do
      ticket = Factories.insert!(:helpdesk_ticket)
      {:ok, _view, html} = live(conn, Routes.live_path(conn, Support.OverviewPage))
      assert html =~ ticket.title
    end
  end
end
