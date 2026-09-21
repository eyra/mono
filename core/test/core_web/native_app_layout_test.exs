defmodule CoreWeb.NativeAppLayoutTest do
  use CoreWeb.ConnCase
  import Phoenix.ConnTest

  setup [:login_as_member]

  test "the NextApp user agent flags the page as native", %{conn: conn} do
    html =
      conn
      |> put_req_header("user-agent", "Mozilla/5.0 (iPhone) NextApp/1.0.0 iOS")
      |> get(~p"/")
      |> html_response(200)

    assert html =~ "data-native-app"
  end

  test "a browser user agent keeps the web chrome", %{conn: conn} do
    html =
      conn
      |> put_req_header("user-agent", "Mozilla/5.0 (iPhone) Safari/604.1")
      |> get(~p"/")
      |> html_response(200)

    refute html =~ "data-native-app"
  end
end
