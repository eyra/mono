defmodule Systems.Admin.LoginPageTest do
  use CoreWeb.ConnCase
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  describe "login page" do
    setup [:login_as_admin]

    test "render", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/admin/login")
      assert html =~ "Sign in with Google account"
    end
  end
end
