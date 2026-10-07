defmodule CoreWeb.NativeAppLayoutTest do
  use CoreWeb.ConnCase

  @native_user_agent "Mozilla/5.0 (iPhone) NextApp/1.0.0 iOS"
  @browser_user_agent "Mozilla/5.0 (iPhone) Safari/604.1"

  describe "home" do
    setup [:login_as_member]

    test "the NextApp user agent flags the page as native", %{conn: conn} do
      html = get_html(conn, ~p"/", @native_user_agent)

      assert html =~ "data-native-app"
    end

    test "a browser user agent keeps the web chrome", %{conn: conn} do
      html = get_html(conn, ~p"/", @browser_user_agent)

      refute html =~ "data-native-app"
    end
  end

  describe "account page for a creator" do
    setup [:login_as_creator]

    test "the NextApp user agent hides the hero", %{conn: conn} do
      document =
        conn |> get_html(~p"/user/account", @native_user_agent) |> Floki.parse_document!()

      assert Floki.find(document, "body[data-native-app]") != []
      assert Floki.find(document, ~s{[class~="native:hidden"] [data-native-title]}) != []
    end

    test "a browser user agent shows the hero", %{conn: conn} do
      document =
        conn |> get_html(~p"/user/account", @browser_user_agent) |> Floki.parse_document!()

      assert Floki.find(document, "body[data-native-app]") == []
      assert Floki.find(document, "[data-native-title]") != []
    end
  end

  defp get_html(conn, path, user_agent) do
    conn
    |> put_req_header("user-agent", user_agent)
    |> get(path)
    |> html_response(200)
  end
end
