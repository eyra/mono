defmodule Next.Account.SignInEntryTest do
  @moduledoc """
  Where Next sends a signed-out person to sign in: the code page when
  sign-in codes (`:otp`) are on, the password page otherwise.
  """
  use CoreWeb.ConnCase, async: false
  use Core.FeatureFlags.Test

  import Phoenix.LiveViewTest

  alias CoreWeb.Endpoint

  @token_salt "otp-redeem"

  @participant_pages [
    "/assignment/1",
    "/assignment/1/landing",
    "/assignment/callback/1",
    "/alliance/1/callback",
    "/pool/panl/join",
    "/pool/panl/onboarding",
    "/pool/1",
    "/pool/1/marketplace",
    "/lab/1"
  ]

  @researcher_pages ["/assignment/1/content", "/pool/1/content", "/pool/participant/1"]

  describe "with sign-in codes on" do
    setup do
      set_feature_flag(:otp, true)
      :ok
    end

    test "the sign-in page is the code page" do
      assert Next.SaaS.sign_in_page() == "/user/auth/identify"
    end

    test "the menu's Sign in goes to the code page" do
      assert %{signin: %{action: %{to: "/user/auth/identify"}}} = Next.Menu.Items.values()
    end

    test "a protected page sends a signed-out visitor to the code page", %{conn: conn} do
      conn = get(conn, ~p"/user/account")

      assert redirected_to(conn) == "/user/auth/identify"
      assert get_session(conn, :user_return_to) == "/user/account"
    end

    test "signing in with a code returns to the protected page", %{conn: conn} do
      user = Factories.insert!(:member)
      conn = get(conn, ~p"/user/account")

      token =
        Phoenix.Token.sign(Endpoint, @token_salt, %{
          user_id: user.id,
          email: user.email,
          return_to: nil
        })

      conn = conn |> recycle() |> get(~p"/user/auth/redeem?token=#{token}")

      assert redirected_to(conn) == "/user/account"
    end

    test "signing out goes to the code page", %{conn: conn} do
      {:ok, conn: conn, user: _} = Factories.insert!(:member) |> login(%{conn: conn})

      conn = delete(conn, ~p"/user/session")

      assert redirected_to(conn) == "/user/auth/identify"
    end

    test "the code page links to password sign-in", %{conn: conn} do
      set_feature_flag(:password_sign_in, true)

      {:ok, view, _html} = live(conn, ~p"/user/auth/identify")

      assert view |> element("[data-testid='auth-password-link']") |> render() =~
               ~s(href="/user/signin")
    end

    test "the password link keeps the return path", %{conn: conn} do
      set_feature_flag(:password_sign_in, true)

      {:ok, view, _html} = live(conn, ~p"/user/auth/identify?return_to=/pool/panl/join")

      assert view |> element("[data-testid='auth-password-link']") |> render() =~
               ~s(href="/user/session?return_to=%2Fpool%2Fpanl%2Fjoin")
    end

    test "the code page hides the password link when password sign-in is off", %{conn: conn} do
      set_feature_flag(:password_sign_in, false)

      {:ok, view, _html} = live(conn, ~p"/user/auth/identify")

      refute has_element?(view, "[data-testid='auth-password-link']")
    end

    test "the participant entry has no password link", %{conn: conn} do
      set_feature_flag(:password_sign_in, true)

      {:ok, view, _html} = live(conn, ~p"/user/auth/identify/participant")

      refute has_element?(view, "[data-testid='auth-password-link']")
    end

    test "the password page keeps working", %{conn: conn} do
      set_feature_flag(:password_sign_in, true)

      {:ok, _view, html} = live(conn, ~p"/user/signin")

      assert html =~ "signin-form"
    end

    for path <- @participant_pages do
      test "participant page #{path} goes to the participant code page", %{conn: conn} do
        conn = get(conn, unquote(path))

        assert redirected_to(conn) ==
                 "/user/auth/identify/participant?return_to=#{URI.encode_www_form(unquote(path))}"

        assert get_session(conn, :user_return_to) == unquote(path)
      end
    end

    for path <- @researcher_pages do
      test "researcher page #{path} goes to the code page", %{conn: conn} do
        conn = get(conn, unquote(path))

        assert redirected_to(conn) == "/user/auth/identify"
      end
    end

    test "a new email from a participant page continues as a participant", %{conn: conn} do
      conn = get(conn, "/pool/panl/join")
      {:ok, view, _html} = conn |> recycle() |> live(redirected_to(conn))
      email = "participant-#{System.unique_integer([:positive])}@example.invalid"

      render_submit(view, "submit", %{"email" => email})

      assert_redirect(
        view,
        "/user/auth/verify?email=#{URI.encode_www_form(email)}&return_to=%2Fpool%2Fpanl%2Fjoin&creator=false"
      )
    end

    test "a protected participant page still goes to the participant entry", %{conn: conn} do
      conn = get(conn, "/assignment/1/invite")

      assert redirected_to(conn) ==
               "/user/auth/identify/participant?return_to=%2Fassignment%2F1%2Finvite"
    end
  end

  describe "with sign-in codes off" do
    setup do
      set_feature_flag(:otp, false)
      :ok
    end

    test "the sign-in page is the password page" do
      assert Next.SaaS.sign_in_page() == "/user/signin"
    end

    test "the menu's Sign in goes to the password page" do
      assert %{signin: %{action: %{to: "/user/signin"}}} = Next.Menu.Items.values()
    end

    test "a protected page sends a signed-out visitor to the password page", %{conn: conn} do
      conn = get(conn, ~p"/user/account")

      assert redirected_to(conn) == "/user/signin"
      assert get_session(conn, :user_return_to) == "/user/account"
    end

    for path <- @participant_pages do
      test "participant page #{path} goes to the password page", %{conn: conn} do
        conn = get(conn, unquote(path))

        assert redirected_to(conn) == "/user/signin"
        assert get_session(conn, :user_return_to) == unquote(path)
      end
    end

    test "signing out goes to the password page", %{conn: conn} do
      {:ok, conn: conn, user: _} = Factories.insert!(:member) |> login(%{conn: conn})

      conn = delete(conn, ~p"/user/session")

      assert redirected_to(conn) == "/user/signin"
    end
  end
end
