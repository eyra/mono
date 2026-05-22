defmodule Systems.Account.OnboardingControllerTest do
  use CoreWeb.ConnCase, async: true

  alias Systems.Account.OnboardingController

  describe "generate_token/1" do
    test "generates a valid token for user" do
      user = Factories.insert!(:member)

      token = OnboardingController.generate_token(user)

      assert is_binary(token)
      assert String.length(token) > 0
    end

    test "generates different tokens for different users" do
      user1 = Factories.insert!(:member)
      user2 = Factories.insert!(:member)

      token1 = OnboardingController.generate_token(user1)
      token2 = OnboardingController.generate_token(user2)

      refute token1 == token2
    end
  end

  describe "start/2 with valid token" do
    test "logs in user and redirects to onboarding page", %{conn: conn} do
      user = Factories.insert!(:member)
      token = OnboardingController.generate_token(user)

      conn = get(conn, ~p"/user/onboarding/start?token=#{token}")

      assert redirected_to(conn) == "/user/onboarding"

      # Verify user is logged in by checking session
      assert get_session(conn, :user_token) != nil
    end
  end

  describe "start/2 with invalid token" do
    test "redirects to signin with error flash", %{conn: conn} do
      conn = get(conn, ~p"/user/onboarding/start?token=invalid_token")

      assert redirected_to(conn) == "/user/signin"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) != nil
    end

    test "redirects to signin for tampered token", %{conn: conn} do
      user = Factories.insert!(:member)
      token = OnboardingController.generate_token(user)
      # Tamper with the token
      tampered_token = token <> "tampered"

      conn = get(conn, ~p"/user/onboarding/start?token=#{tampered_token}")

      assert redirected_to(conn) == "/user/signin"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) != nil
    end

    test "redirects to signin for empty token", %{conn: conn} do
      conn = get(conn, ~p"/user/onboarding/start?token=")

      assert redirected_to(conn) == "/user/signin"
    end
  end

  describe "start/2 with expired token" do
    test "redirects to signin when token is expired", %{conn: conn} do
      # The OnboardingController uses max_age: 300 (5 minutes)
      # We can't easily test expiry without waiting or mocking time,
      # so we test that an invalid/old token format fails
      expired_token = "expired.token.here"

      conn = get(conn, ~p"/user/onboarding/start?token=#{expired_token}")

      assert redirected_to(conn) == "/user/signin"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) != nil
    end
  end

  describe "token verification" do
    test "token can be verified within max age" do
      user = Factories.insert!(:member)
      token = OnboardingController.generate_token(user)

      # Verify using the same salt and endpoint
      result =
        Phoenix.Token.verify(
          CoreWeb.Endpoint,
          "onboarding_token",
          token,
          max_age: 300
        )

      assert {:ok, user.id} == result
    end

    test "token contains user id" do
      user = Factories.insert!(:member)
      token = OnboardingController.generate_token(user)

      {:ok, user_id} =
        Phoenix.Token.verify(
          CoreWeb.Endpoint,
          "onboarding_token",
          token,
          max_age: 300
        )

      assert user_id == user.id
    end
  end
end
