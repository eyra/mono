defmodule Systems.Account.UserProfilePageTest do
  use CoreWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "with authenticated user" do
    setup [:login_as_member]

    test "show info on load", %{conn: conn, user: user} do
      {:ok, _view, html} = live(conn, ~p"/user/profile")
      assert html =~ user.displayname
    end

    test "allow altering the user info", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/user/profile")

      view
      |> element("#main_form")
      |> render_change(%{"user_profile_edit" => %{"displayname" => "A new name"}}) =~ "A new name"
    end
  end
end
