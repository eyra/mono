defmodule Next.Account.AuthOtpFlagTest do
  use CoreWeb.ConnCase, async: false
  use Core.FeatureFlags.Test

  import Phoenix.LiveViewTest

  describe "/user/auth with :otp feature flag disabled" do
    test "redirects to /user/signin", %{conn: conn} do
      set_feature_flag(:otp, false)

      assert {:error, {:redirect, %{to: "/user/signin"}}} =
               live(conn, ~p"/user/auth")
    end
  end

  describe "/user/auth/verify with :otp feature flag disabled" do
    test "redirects to /user/signin", %{conn: conn} do
      set_feature_flag(:otp, false)

      assert {:error, {:redirect, %{to: "/user/signin"}}} =
               live(conn, ~p"/user/auth/verify?email=anyone@example.com")
    end
  end

  describe "GET /user/auth/finalize with :otp feature flag disabled" do
    test "redirects to /user/signin", %{conn: conn} do
      set_feature_flag(:otp, false)

      conn = get(conn, ~p"/user/auth/finalize?token=irrelevant")
      assert redirected_to(conn) == "/user/signin"
    end
  end
end
