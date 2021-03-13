defmodule CoreWeb.Live.User.Signup.Test do
  use CoreWeb.ConnCase
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  alias CoreWeb.User.Signup
  alias Core.Factories

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
      {:ok, view, _html} = live(conn, Routes.live_path(conn, CoreWeb.User.Signup))

      view
      |> element("form")
      |> render_submit(%{
        user: %{email: Faker.Internet.email(), password: Factories.valid_user_password()}
      })

      assert_redirect(view, "/user/await-confirmation")
    end
  end
end
