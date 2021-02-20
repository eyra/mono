defmodule LinkWeb.Live.User.Signup.Test do
  use LinkWeb.ConnCase
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  import Ecto.Query
  alias LinkWeb.User.Signup
  alias Link.Factories

  describe "as a visitor" do
    test "signup with low-quality password fails", %{conn: conn} do
      {:ok, view, _html} = live(conn, Routes.live_path(conn, Signup))

      html =
        view
        |> element("form")
        |> render_submit(%{user: %{email: Faker.Internet.email(), password: "abc"}})

      assert html =~ "at least"
    end

    test "signup redirects to confirmation view", %{conn: conn} do
      {:ok, view, _html} = live(conn, Routes.live_path(conn, Signup))

      view
      |> element("form")
      |> render_submit(%{
        user: %{email: Faker.Internet.email(), password: Factories.valid_user_password()}
      })

      assert_redirect(view, "/user/await-confirmation")
    end
  end
end
