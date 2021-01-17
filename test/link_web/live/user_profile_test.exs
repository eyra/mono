defmodule LinkWeb.Live.UserProfileTest do
  use LinkWeb.ConnCase
  import Plug.Conn
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  alias LinkWeb.UserProfile
  alias Link.Users.User
  # @endpoint MyEndpoint

  alias Link.Factories

  @invalid_attrs %{fullname: nil, displayname: nil}

  setup %{conn: conn} do
    user = Factories.insert!(:member)

    conn =
      post(conn, Routes.pow_session_path(conn, :create),
        user: %{email: user.email, password: "S4p3rS3cr3t"}
      )

    {:ok, conn: conn, user: user}
  end

  describe "edit a profile" do
    test "renders form for editing the users profile", %{conn: conn} do
      {:ok, view, _html} = live(conn, Routes.live_path(conn, UserProfile.Index))
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
