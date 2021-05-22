defmodule CoreWeb.Live.User.ResetPassword.Test do
  use CoreWeb.ConnCase, async: true
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  alias CoreWeb.User.ResetPassword
  alias Core.Accounts
  alias Core.Factories
  alias Core.Repo

  describe "as a visitor" do
    test "reset form validates the email field", %{conn: conn} do
      {:ok, view, _html} = live(conn, Routes.live_path(conn, ResetPassword))

      html =
        view
        |> element("form")
        |> render_submit(%{user: %{email: "a b c d"}})

      assert html =~ "Invalid email address"
    end

    test "reset form fakes sending mail when user does not exist", %{conn: conn} do
      {:ok, view, _html} = live(conn, Routes.live_path(conn, ResetPassword))

      html =
        view
        |> element("form")
        |> render_submit(%{user: %{email: Faker.Internet.email()}})

      assert html =~ "you will receive instructions"
      assert Repo.all(Accounts.UserToken) == []
    end

    test "reset form sends token to user", %{conn: conn} do
      user = Factories.insert!(:member, %{confirmed_at: nil})
      {:ok, view, _html} = live(conn, Routes.live_path(conn, ResetPassword))

      html =
        view
        |> element("form")
        |> render_submit(%{user: %{email: user.email}})

      assert html =~ "you will receive instructions"
      assert Repo.get_by!(Accounts.UserToken, user_id: user.id).context == "reset_password"
    end
  end
end
