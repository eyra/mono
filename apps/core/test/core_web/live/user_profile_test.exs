defmodule CoreWeb.Live.UserProfileTest do
  use CoreWeb.ConnCase
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  alias CoreWeb.User.Profile

  describe "edit a profile" do
    setup [:login_as_member]

    test "renders form for editing the users profile", %{conn: conn} do
      {:ok, view, _html} = live(conn, Routes.live_path(conn, Profile))
      fullname = Faker.Person.name()
      displayname = Faker.Person.first_name()

      # Editing the profile should update it
      html =
        view
        |> element("form")
        |> render_change(%{profile: %{fullname: fullname, displayname: displayname}})

      assert html =~ fullname
      assert html =~ displayname
    end
  end
end
