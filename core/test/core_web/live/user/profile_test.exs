defmodule CoreWeb.User.ProfileTest do
  use CoreWeb.ConnCase
  alias CoreWeb.User.Profile
  import Phoenix.LiveViewTest

  describe "with authenticated user" do
    setup [:login_as_member]

    test "show info on load", %{conn: conn, user: user} do
      {:ok, _view, html} = live(conn, Routes.live_path(conn, Profile))
      assert html =~ user.displayname
    end

    test "allow altering the user info", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, Routes.live_path(conn, Profile))

      view
      |> element("#main_form")
      |> render_change(%{"user_profile_edit" => %{"displayname" => "A new name"}}) =~ "A new name"
    end
  end
end
