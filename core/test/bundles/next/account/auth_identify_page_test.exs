defmodule Next.Account.AuthIdentifyPageTest do
  use CoreWeb.ConnCase, async: false
  use Core.FeatureFlags.Test

  import Phoenix.LiveViewTest

  test "participant entry uses the shared identify page", %{conn: conn} do
    set_feature_flag(:otp, true)

    {:ok, _view, html} = live(conn, "/user/auth/identify/participant")

    assert html =~ "auth-email-input"
    refute html =~ "auth-signin-button"
  end

  test "participant entry carries its role into OTP verification", %{conn: conn} do
    set_feature_flag(:otp, true)
    email = "participant-#{System.unique_integer([:positive])}@example.invalid"

    {:ok, view, _html} = live(conn, "/user/auth/identify/participant")
    render_submit(view, "submit", %{"email" => email})

    assert_redirect(view, "/user/auth/verify?email=#{URI.encode_www_form(email)}&creator=false")
  end
end
