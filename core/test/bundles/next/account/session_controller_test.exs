defmodule Next.Account.SessionControllerTest do
  @moduledoc """
  Integration coverage for the redeem step of the email-first OTP flow.
  """
  use CoreWeb.ConnCase, async: false
  use Core.FeatureFlags.Test

  alias CoreWeb.Endpoint
  alias Next.Account.AuthCodeVerifyPage

  @token_salt "otp-redeem"

  setup %{conn: conn} do
    set_feature_flag(:otp, true)
    %{conn: conn}
  end

  describe "GET /user/auth/redeem — new user, no return_to" do
    test "registers, logs in, and lands on /user/onboarding", %{conn: conn} do
      email = "fresh-#{Faker.UUID.v4()}@example.com"

      token =
        Phoenix.Token.sign(Endpoint, @token_salt, %{
          user_id: nil,
          email: email,
          return_to: nil
        })

      conn = get(conn, ~p"/user/auth/redeem?token=#{token}")

      assert redirected_to(conn) == "/user/onboarding"
    end
  end

  describe "GET /user/auth/redeem — new user, with return_to" do
    # New users always land on /user/onboarding first; the return_to is
    # preserved as a URL param so onboarding can chain the user into the
    # requested destination when the flow finishes.
    test "lands on /user/onboarding?return_to=<path>", %{conn: conn} do
      email = "fresh-#{Faker.UUID.v4()}@example.com"

      token =
        Phoenix.Token.sign(Endpoint, @token_salt, %{
          user_id: nil,
          email: email,
          return_to: "/pool/panl/join"
        })

      conn = get(conn, ~p"/user/auth/redeem?token=#{token}")

      assert redirected_to(conn) == "/user/onboarding?return_to=%2Fpool%2Fpanl%2Fjoin"
    end
  end

  describe "GET /user/auth/redeem — existing user, with return_to" do
    # Existing users go straight to the return_to destination — no
    # onboarding stop needed.
    test "lands on the return_to path directly", %{conn: conn} do
      user =
        Factories.insert!(:member, %{
          email: "existing-#{Faker.UUID.v4()}@example.com",
          creator: false,
          confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        })

      token =
        Phoenix.Token.sign(Endpoint, @token_salt, %{
          user_id: user.id,
          email: user.email,
          return_to: "/pool/panl/join"
        })

      conn = get(conn, ~p"/user/auth/redeem?token=#{token}")

      assert redirected_to(conn) == "/pool/panl/join"
    end
  end

  describe "AuthCodeVerifyPage.decode_redeem_token/1" do
    test "roundtrips :return_to alongside :user_id and :email" do
      payload = %{user_id: 42, email: "x@example.com", return_to: "/pool/panl/join"}
      token = Phoenix.Token.sign(Endpoint, @token_salt, payload)

      assert {:ok, ^payload} = AuthCodeVerifyPage.decode_redeem_token(token)
    end
  end
end
