defmodule CoreWeb.Live.User.ResetPassword.Test do
  use CoreWeb.ConnCase, async: true
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Core.Factories
  alias Core.Repo
  alias Systems.Account

  describe "as a visitor" do
    test "reset form validates the email field", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/user/reset-password")

      html =
        view
        |> element("form")
        |> render_submit(%{user: %{email: "a b c d"}})

      assert html =~ "Sign in"
    end

    test "reset form fakes sending mail when user does not exist", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/user/reset-password")

      html =
        view
        |> element("form")
        |> render_submit(%{user: %{email: Faker.Internet.email()}})

      assert html =~ "you will receive instructions shortly"
      assert Repo.all(Account.UserTokenModel) == []
    end

    test "reset form sends token to user", %{conn: conn} do
      user = Factories.insert!(:member, %{confirmed_at: nil})
      {:ok, view, _html} = live(conn, ~p"/user/reset-password")

      html =
        view
        |> element("form")
        |> render_submit(%{user: %{email: user.email}})

      assert html =~ "you will receive instructions shortly"
      assert Repo.get_by!(Account.UserTokenModel, user_id: user.id).context == "reset_password"
    end
  end
end
