defmodule Systems.Feldspar.AppPageTest do
  use CoreWeb.ConnCase
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  describe "render an app page" do
    test "renders page with iframe", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/feldspar/apps/test")
      assert html =~ "<iframe"
    end
  end

  describe "handle app_event" do
    test "can receive random app_event data", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/feldspar/apps/test")

      assert render_hook(view, :app_event, %{unexpected_key: "some data"}) =~
               "Unsupported "
    end
  end
end
