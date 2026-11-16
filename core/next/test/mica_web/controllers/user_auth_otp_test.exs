defmodule NextWeb.UserAuthOtpTest do
  # With sign-in codes on, the SaaS's sign_in_page/0 is its code page, but the
  # pages Mica sends users to after signing out stay on the page with every way
  # to sign in (sign_in_options_page/0). Sets the global :otp flag.
  use NextWeb.ConnCase, async: false
  use Mica.FeatureFlags.Test

  alias Systems.Account.UserAuth

  setup %{conn: conn} do
    set_feature_flag(:otp, true)
    %{conn: init_test_session(conn, %{})}
  end

  test "the SaaS's sign-in page is its code page", _ctx do
    assert Mica.SaaS.module().sign_in_page() == "/user/auth/identify"
  end

  test "signing out ends on the page with every way to sign in", %{conn: conn} do
    conn = conn |> fetch_cookies() |> UserAuth.log_out_user()
    assert redirected_to(conn) == "/user/signin"
  end
end
