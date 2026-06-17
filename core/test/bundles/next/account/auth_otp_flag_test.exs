defmodule Next.Account.AuthOtpFlagTest do
  use CoreWeb.ConnCase, async: false
  use Core.FeatureFlags.Test

  import Phoenix.LiveViewTest

  describe "/user/auth/identify with :otp feature flag disabled" do
    test "redirects to /user/signin", %{conn: conn} do
      set_feature_flag(:otp, false)

      assert {:error, {:redirect, %{to: "/user/signin"}}} =
               live(conn, ~p"/user/auth/identify")
    end
  end

  describe "/user/auth/verify with :otp feature flag disabled" do
    test "redirects to /user/signin", %{conn: conn} do
      set_feature_flag(:otp, false)

      assert {:error, {:redirect, %{to: "/user/signin"}}} =
               live(conn, ~p"/user/auth/verify?email=anyone@example.com")
    end
  end

  describe "GET /user/auth/redeem with :otp feature flag disabled" do
    test "redirects to /user/signin", %{conn: conn} do
      set_feature_flag(:otp, false)

      conn = get(conn, ~p"/user/auth/redeem?token=irrelevant")
      assert redirected_to(conn) == "/user/signin"
    end
  end
end
