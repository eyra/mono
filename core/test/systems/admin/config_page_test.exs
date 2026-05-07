defmodule Systems.Admin.ConfigPageTest do
  use CoreWeb.ConnCase
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  describe "config page" do
    setup [:login_as_admin]

    test "render", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/admin/config")
      assert html =~ "Admin"
    end

    test "create bank account", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/config")

      # Get reference to embedded SystemView and send event there
      system_view = find_live_child(view, "admin_system_view")
      render_click(system_view, "create_bank_account", %{"item" => "first"})

      # re-render for async popup
      assert render(view) =~ "Bank account"
    end

    test "create citizen pool", %{conn: conn} do
      Factories.insert!(:currency, %{name: "euro", type: :legal, decimal_scale: 2})

      {:ok, view, _html} = live(conn, ~p"/admin/config")

      # Get reference to embedded SystemView and send event there
      system_view = find_live_child(view, "admin_system_view")
      render_click(system_view, "create_citizen_pool", %{"item" => "first"})

      # re-render for async popup
      assert render(view) =~ "New pool"
    end
  end
end
