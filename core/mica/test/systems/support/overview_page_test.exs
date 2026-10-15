defmodule Systems.Support.OverviewPageTest do
  use CoreWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  alias Core.Factories

  describe "require admin role" do
    setup [:login_as_member]

    test "deny access to non-admin", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/access_denied"}}} = live(conn, ~p"/support/ticket")
    end
  end

  describe "helpdesk tickets" do
    setup [:login_as_admin]

    test "list open tickets", %{conn: conn} do
      ticket = Factories.insert!(:helpdesk_ticket)
      {:ok, _view, html} = live(conn, ~p"/support/ticket")
      assert html =~ ticket.title
    end
  end
end
