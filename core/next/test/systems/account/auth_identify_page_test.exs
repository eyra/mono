defmodule Next.Systems.Account.AuthIdentifyPageTest do
  use MicaWeb.ConnCase, async: false
  use Mica.FeatureFlags.Test
  use Gettext, backend: MicaWeb.Gettext

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

  test "the form submits in place so the email field keeps its focus", %{conn: conn} do
    set_feature_flag(:otp, true)

    {:ok, view, _html} = live(conn, "/user/auth/identify/participant")

    assert has_element?(view, "form#auth_form[phx-hook='SubmitInPlace'][phx-submit='submit']")
  end

  test "a message already shown stays while the next request is routed", %{conn: conn} do
    set_feature_flag(:otp, true)
    email = "limited-#{System.unique_integer([:positive])}@example.com"
    Stream.repeatedly(fn -> AuthCodeLimits.count_request?(email) end) |> Enum.find(&(!&1))
    message = dgettext("eyra-account", "auth.email.rate_limited")

    {:ok, view, _html} = live(conn, "/user/auth/identify/participant")
    render_submit(view, "submit", %{"email" => email})
    assert render(view) =~ message

    # The reply to the submit itself, before routing renders the outcome.
    loading_html = render_submit(view, "submit", %{"email" => email})
    assert loading_html =~ "prism-btn-loading"
    assert loading_html =~ message

    assert render(view) =~ message
  end

  test "a changed email clears the message before the next request", %{conn: conn} do
    set_feature_flag(:otp, true)
    email = "limited-#{System.unique_integer([:positive])}@example.com"
    Stream.repeatedly(fn -> AuthCodeLimits.count_request?(email) end) |> Enum.find(&(!&1))

    {:ok, view, _html} = live(conn, "/user/auth/identify/participant")
    render_submit(view, "submit", %{"email" => email})
    render_change(view, "change", %{"email" => "other@example.com"})

    loading_html = render_submit(view, "submit", %{"email" => "other@example.com"})
    refute loading_html =~ dgettext("eyra-account", "auth.email.rate_limited")
  end

  test "a message for an earlier address doesn't stay under a corrected one", %{conn: conn} do
    set_feature_flag(:otp, true)

    {:ok, view, _html} = live(conn, "/user/auth/identify/participant")

    assert render_submit(view, "submit", %{"email" => "someone@example"}) =~
             dgettext("eyra-account", "auth.email.invalid")

    # Submitted within the change event's debounce, so no change event in between.
    loading_html = render_submit(view, "submit", %{"email" => "someone@example.com"})
    assert loading_html =~ "prism-btn-loading"
    refute loading_html =~ dgettext("eyra-account", "auth.email.invalid")
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
