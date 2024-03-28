defmodule CoreWeb.Live.User.ConfirmToken.Test do
  use CoreWeb.ConnCase, async: true
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  alias CoreWeb.User.ConfirmToken
  alias Core.Accounts
  alias Core.Factories
  alias Core.Repo

  describe "as a visitor" do
    test "a valid token activates the account", %{conn: conn} do
      user = Factories.insert!(:member, %{confirmed_at: nil})

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user, url)
        end)

      {:ok, view, _html} = live(conn, Routes.live_path(conn, ConfirmToken, token))

      {:error, {:redirect, %{to: to}}} =
        view
        |> element("[phx-click=\"confirm\"]")
        |> render_click()

      assert to == "/user/signin?#{URI.encode_query(%{email: user.email})}"
      assert Accounts.get_user!(user.id).confirmed_at
    end

    test "a valid token can be used only once", %{conn: conn} do
      user = Factories.insert!(:member, %{confirmed_at: nil})

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user, url)
        end)

      {:ok, view, _html} = live(conn, Routes.live_path(conn, ConfirmToken, token))

      {:error, {:redirect, %{to: _to}}} =
        view
        |> element("[phx-click=\"confirm\"]")
        |> render_click()

      # The second time should not redirect
      {:ok, view, _html} = live(conn, Routes.live_path(conn, ConfirmToken, "abc"))

      html =
        view
        |> element("[phx-click=\"confirm\"]")
        |> render_click()

      assert html =~ "Account activation"
    end

    test "an invalid token does not activate the account", %{conn: conn} do
      user = Factories.insert!(:member, %{confirmed_at: nil})
      {:ok, view, _html} = live(conn, Routes.live_path(conn, ConfirmToken, "abc"))

      view
      |> element("[phx-click=\"confirm\"]")
      |> render_click()

      refute user.confirmed_at
    end

    test "an invalid token shows resend form", %{conn: conn} do
      {:ok, view, _html} = live(conn, Routes.live_path(conn, ConfirmToken, "abc"))

      html =
        view
        |> element("[phx-click=\"confirm\"]")
        |> render_click()

      assert html =~ "Account activation"
    end

    test "resend form validates the email field", %{conn: conn} do
      {:ok, view, _html} = live(conn, Routes.live_path(conn, ConfirmToken, "test"))

      view
      |> element("[phx-click=\"confirm\"]")
      |> render_click()

      html =
        view
        |> element("form")
        |> render_submit(%{user: %{email: "a b c d"}})

      assert html =~
               "Your account might already have been activated or the activation link is expired."
    end

    test "resend form fakes sending mail when user does not exist", %{conn: conn} do
      {:ok, view, _html} = live(conn, Routes.live_path(conn, ConfirmToken, "test"))

      view
      |> element("[phx-click=\"confirm\"]")
      |> render_click()

      html =
        view
        |> element("form")
        |> render_submit(%{user: %{email: Faker.Internet.email()}})

      assert html =~ "receive instructions"
      assert Repo.all(Accounts.UserToken) == []
    end

    test "resend form sends new token to not-yet activated user", %{conn: conn} do
      user = Factories.insert!(:member, %{confirmed_at: nil})
      {:ok, view, _html} = live(conn, Routes.live_path(conn, ConfirmToken, "test"))

      view
      |> element("[phx-click=\"confirm\"]")
      |> render_click()

      html =
        view
        |> element("form")
        |> render_submit(%{user: %{email: user.email}})

      assert html =~ "receive instructions"
      assert Repo.get_by!(Accounts.UserToken, user_id: user.id).context == "confirm"
    end

    test "resend form sends login info to already activated user", %{conn: conn} do
      user = Factories.insert!(:member, %{confirmed_at: nil})
      {:ok, view, _html} = live(conn, Routes.live_path(conn, ConfirmToken, "test"))

      view
      |> element("[phx-click=\"confirm\"]")
      |> render_click()

      html =
        view
        |> element("form")
        |> render_submit(%{user: %{email: user.email}})

      assert html =~ "receive instructions"
    end
  end

  describe "as a member" do
    setup [:login_as_member]

    test "opening activation mail with expired (invalid) token should redirect", %{conn: conn} do
      {:error, {:redirect, %{to: _}}} = live(conn, Routes.live_path(conn, ConfirmToken, "abc"))
    end
  end
end
