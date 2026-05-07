defmodule CoreWeb.Live.User.SignupPage.Test do
  use CoreWeb.ConnCase
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Core.Factories
  alias Systems.Account.User

  describe "as a visitor" do
    test "signup without accepting next privacy policy shows error and does not create user", %{
      conn: conn
    } do
      email = Faker.Internet.email()
      {:ok, view, _html} = live(conn, ~p"/user/signup/creator")

      user_count_before = Core.Repo.aggregate(User, :count, :id)

      html =
        view
        |> element("form")
        |> render_submit(%{
          user: %{email: email, password: Factories.valid_user_password()}
        })

      assert html =~ "You must accept the terms, conditions and privacy policy to continue"
      user_count_after = Core.Repo.aggregate(User, :count, :id)

      assert user_count_before == user_count_after,
             "User should NOT be created without accepting T&C"

      refute Core.Repo.get_by(User, email: email),
             "User with email #{email} should not exist"
    end

    test "signup without accepting PANL privacy policy shows error and does not create user", %{
      conn: conn
    } do
      email = Faker.Internet.email()
      {:ok, view, _html} = live(conn, ~p"/user/signup/creator?post_signup_action=add_to_panl")

      view
      |> element("[data-selector-item='next_privacy_policy_accepted']")
      |> render_click()

      user_count_before = Core.Repo.aggregate(User, :count, :id)

      html =
        view
        |> element("form")
        |> render_submit(%{
          user: %{email: email, password: Factories.valid_user_password()}
        })

      assert html =~ "You must accept the privacy policy to continue"
      user_count_after = Core.Repo.aggregate(User, :count, :id)

      assert user_count_before == user_count_after,
             "User should NOT be created without accepting PANL privacy policy"

      refute Core.Repo.get_by(User, email: email),
             "User with email #{email} should not exist"
    end

    test "signup with low-quality password fails", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/user/signup/participant")

      view
      |> element("[data-selector-item='next_privacy_policy_accepted']")
      |> render_click()

      html =
        view
        |> element("form")
        |> render_submit(%{user: %{email: Faker.Internet.email(), password: "abc"}})

      assert html =~ "at least"
    end

    test "signup with accepted next privacy policy redirects to confirmation view", %{
      conn: conn
    } do
      {:ok, view, _html} = live(conn, ~p"/user/signup/creator")

      view
      |> element("[data-selector-item='next_privacy_policy_accepted']")
      |> render_click()

      view
      |> element("form")
      |> render_submit(%{
        user: %{email: Faker.Internet.email(), password: Factories.valid_user_password()}
      })

      assert_redirect(view, "/user/await-confirmation")
    end
  end
end
