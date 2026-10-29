defmodule Next.Account.AuthIdentifyPageTest do
  use CoreWeb.ConnCase, async: false
  use Core.FeatureFlags.Test
  use Gettext, backend: CoreWeb.Gettext

  import Phoenix.LiveViewTest

  alias Systems.Account.AuthCodeLimits

  test "participant entry uses the shared identify page", %{conn: conn} do
    set_feature_flag(:otp, true)

    {:ok, _view, html} = live(conn, "/user/auth/identify/participant")

    assert html =~ "auth-email-input"
    refute html =~ "auth-signin-button"
    assert html =~ "auth-continue-button"
  end

  test "invalid email does not show the loading spinner", %{conn: conn} do
    set_feature_flag(:otp, true)

    {:ok, view, _html} = live(conn, "/user/auth/identify/participant")
    html = render_submit(view, "submit", %{"email" => ""})

    assert html =~ dgettext("eyra-account", "auth.email.invalid")
    refute html =~ "prism-btn-loading"
  end

  test "participant entry carries its role into OTP verification", %{conn: conn} do
    set_feature_flag(:otp, true)
    email = "participant-#{System.unique_integer([:positive])}@example.invalid"

    {:ok, view, _html} = live(conn, "/user/auth/identify/participant")
    render_submit(view, "submit", %{"email" => email})

    assert_redirect(view, "/user/auth/verify?email=#{URI.encode_www_form(email)}&creator=false")
  end

  test "a network address past its request limit gets the request limit message", %{conn: conn} do
    set_feature_flag(:otp, true)

    for i <- 1..200,
        do: assert(AuthCodeLimits.allow_request?("other-#{i}@example.com", "198.51.100.8"))

    conn = put_req_header(conn, "x-forwarded-for", "198.51.100.8")
    {:ok, view, _html} = live(conn, "/user/auth/identify/participant")
    render_submit(view, "submit", %{"email" => "network-limited@example.com"})

    assert render(view) =~ dgettext("eyra-account", "auth.email.rate_limited")
  end
end
