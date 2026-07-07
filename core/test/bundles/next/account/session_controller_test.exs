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

  describe "GET /user/auth/redeem — new user, no after action" do
    test "registers, logs in, and lands on /user/onboarding", %{conn: conn} do
      email = "fresh-#{Faker.UUID.v4()}@example.com"

      token =
        Phoenix.Token.sign(Endpoint, @token_salt, %{
          user_id: nil,
          email: email,
          after: nil
        })

      conn = get(conn, ~p"/user/auth/redeem?token=#{token}")

      assert redirected_to(conn) == "/user/onboarding"
    end
  end

  describe "GET /user/auth/redeem — new user, with after action" do
    test "lands on /user/onboarding?after=<action>", %{conn: conn} do
      email = "fresh-#{Faker.UUID.v4()}@example.com"

      token =
        Phoenix.Token.sign(Endpoint, @token_salt, %{
          user_id: nil,
          email: email,
          after: "join_pool:panl"
        })

      conn = get(conn, ~p"/user/auth/redeem?token=#{token}")

      assert redirected_to(conn) == "/user/onboarding?after=join_pool%3Apanl"
    end
  end

  describe "GET /user/auth/redeem — existing user, with after action" do
    test "lands on the post-signin destination with ?after=<action> appended", %{conn: conn} do
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
          after: "join_pool:panl"
        })

      conn = get(conn, ~p"/user/auth/redeem?token=#{token}")

      redirected = redirected_to(conn)
      assert redirected =~ "after=join_pool%3Apanl"
    end
  end

  describe "AuthCodeVerifyPage.decode_redeem_token/1" do
    test "roundtrips :after alongside :user_id and :email" do
      payload = %{user_id: 42, email: "x@example.com", after: "join_pool:panl"}
      token = Phoenix.Token.sign(Endpoint, @token_salt, payload)

      assert {:ok, ^payload} = AuthCodeVerifyPage.decode_redeem_token(token)
    end
  end
end
