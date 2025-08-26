defmodule CoreWeb.Live.User.ConfirmToken.Test do
  use CoreWeb.ConnCase, async: true
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Core.Factories
  alias Core.Repo
  alias Systems.Account

  describe "as a visitor" do
    test "a valid token activates the account", %{conn: conn} do
      user = Factories.insert!(:member, %{confirmed_at: nil})

      token =
        extract_user_token(fn url ->
          Account.Public.deliver_user_confirmation_instructions(user, url)
        end)

      {:ok, view, _html} = live(conn, ~p"/user/confirm/#{token}")

      {:error, {:redirect, %{to: to}}} = render_click(view, "confirm")

      assert to ==
               "/user/signin?#{URI.encode_query(%{email: user.email})}&status=account_activated_successfully"

      assert Account.Public.get_user!(user.id).confirmed_at
    end

    test "a valid token can be used only once", %{conn: conn} do
      user = Factories.insert!(:member, %{confirmed_at: nil})

      token =
        extract_user_token(fn url ->
          Account.Public.deliver_user_confirmation_instructions(user, url)
        end)

      {:ok, view, _html} = live(conn, ~p"/user/confirm/#{token}")

      {:error, {:redirect, %{to: _to}}} =
        view
        |> render_click("confirm")

      # The second time should not redirect
      {:ok, view, _html} = live(conn, ~p"/user/confirm/abc")

      html =
        view
        |> render_click("confirm")

      assert html =~ "Account activation"
    end

    test "an invalid token does not activate the account", %{conn: conn} do
      user = Factories.insert!(:member, %{confirmed_at: nil})
      {:ok, view, _html} = live(conn, ~p"/user/confirm/abc")

      view
      |> render_click("confirm")

      refute user.confirmed_at
    end

    test "an invalid token shows resend form", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/user/confirm/abc")

      html =
        view
        |> render_click("confirm")

      assert html =~ "Account activation"
    end

    test "resend form validates the email field", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/user/confirm/test")

      view
      |> render_click("confirm")

      html =
        view
        |> element("form")
        |> render_submit(%{user: %{email: "a b c d"}})

      assert html =~
               "Your account might already have been activated or the activation link is expired."
    end

    test "resend form fakes sending mail when user does not exist", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/user/confirm/test")

      view
      |> render_click("confirm")

      html =
        view
        |> element("form")
        |> render_submit(%{user: %{email: Faker.Internet.email()}})

      assert html =~ "receive instructions"
      assert Repo.all(Account.UserTokenModel) == []
    end

    test "resend form sends new token to not-yet activated user", %{conn: conn} do
      user = Factories.insert!(:member, %{confirmed_at: nil})
      {:ok, view, _html} = live(conn, ~p"/user/confirm/test")

      view
      |> render_click("confirm")

      html =
        view
        |> element("form")
        |> render_submit(%{user: %{email: user.email}})

      assert html =~ "receive instructions"
      assert Repo.get_by!(Account.UserTokenModel, user_id: user.id).context == "confirm"
    end

    test "resend form sends login info to already activated user", %{conn: conn} do
      user = Factories.insert!(:member, %{confirmed_at: nil})
      {:ok, view, _html} = live(conn, ~p"/user/confirm/test")

      view
      |> render_click("confirm")

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
      {:error, {:redirect, %{to: _}}} = live(conn, ~p"/user/confirm/abc")
    end
  end
end
