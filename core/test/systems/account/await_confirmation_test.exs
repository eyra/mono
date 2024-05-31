defmodule Systems.Account.AwaitConfirmationTest do
  use CoreWeb.ConnCase
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  test "render", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/user/await-confirmation")
    assert html =~ "Sign in"
  end
end
