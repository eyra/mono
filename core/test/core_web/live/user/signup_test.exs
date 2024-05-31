defmodule CoreWeb.Live.User.SignupPage.Test do
  use CoreWeb.ConnCase
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Core.Factories

  describe "as a visitor" do
    test "signup with low-quality password fails", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/user/signup/participant")

      html =
        view
        |> element("form")
        |> render_submit(%{user: %{email: Faker.Internet.email(), password: "abc"}})

      assert html =~ "at least"
    end

    test "signup redirects to confirmation view", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/user/signup/creator")

      view
      |> element("form")
      |> render_submit(%{
        user: %{email: Faker.Internet.email(), password: Factories.valid_user_password()}
      })

      assert_redirect(view, "/user/await-confirmation")
    end
  end
end
