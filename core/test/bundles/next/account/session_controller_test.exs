defmodule Next.Account.SessionControllerTest do
  @moduledoc """
  Integration coverage for the redeem step of the email-first OTP flow.
  """
  use CoreWeb.ConnCase, async: false
  use Core.FeatureFlags.Test

  alias CoreWeb.Endpoint
  alias Next.Account.AuthCodeVerifyPage

  @token_salt "otp-redeem"
  @remember_me_cookie "_core_web_user_remember_me"
  @mobile_user_agent "Mozilla/5.0 (iPhone; CPU iPhone OS 18_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.6 Mobile/15E148 Safari/604.1 NextApp/0.1.0 iOS"

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
      refute Systems.Account.Public.get_user_by_email(email).creator
    end
  end

  describe "GET /user/auth/redeem — mobile session" do
    test "creates a persistent HttpOnly mobile cookie", %{conn: conn} do
      user = Factories.insert!(:member)
      token = Phoenix.Token.sign(Endpoint, @token_salt, %{user_id: user.id, email: user.email})

      conn =
        conn
        |> put_req_header("user-agent", @mobile_user_agent)
        |> get(~p"/user/auth/redeem?token=#{token}")

      assert session_token = get_session(conn, :user_token)

      assert %{context: "mobile_session", last_used_at: %NaiveDateTime{}} =
               Core.Repo.get_by(Systems.Account.UserTokenModel, token: session_token)

      assert %{value: signed_token, max_age: 5_184_000, http_only: true} =
               conn.resp_cookies[@remember_me_cookie]

      assert signed_token != session_token
    end

    test "renews the cookie and redirects an active mobile session from identify", %{conn: conn} do
      user = Factories.insert!(:member)
      token = Phoenix.Token.sign(Endpoint, @token_salt, %{user_id: user.id, email: user.email})

      mobile_conn =
        conn
        |> put_req_header("user-agent", @mobile_user_agent)
        |> get(~p"/user/auth/redeem?token=#{token}")

      session_token = get_session(mobile_conn, :user_token)
      %{value: signed_token} = mobile_conn.resp_cookies[@remember_me_cookie]

      last_used_at =
        NaiveDateTime.utc_now()
        |> NaiveDateTime.truncate(:second)
        |> NaiveDateTime.add(-30 * 24 * 60 * 60, :second)

      Core.Repo.update_all(Systems.Account.UserTokenModel, set: [last_used_at: last_used_at])

      conn =
        CoreWeb.ConnCase.build_conn()
        |> put_req_header("user-agent", @mobile_user_agent)
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> get("/user/auth/identify")

      assert redirected_to(conn) == "/"
      assert %{max_age: 5_184_000} = conn.resp_cookies[@remember_me_cookie]

      assert %{last_used_at: renewed_at} =
               Core.Repo.get_by(Systems.Account.UserTokenModel, token: session_token)

      assert NaiveDateTime.compare(renewed_at, last_used_at) == :gt
    end

    test "revokes the mobile token and clears the cookie at sign-out", %{conn: conn} do
      user = Factories.insert!(:member)
      token = Phoenix.Token.sign(Endpoint, @token_salt, %{user_id: user.id, email: user.email})

      mobile_conn =
        conn
        |> put_req_header("user-agent", @mobile_user_agent)
        |> get(~p"/user/auth/redeem?token=#{token}")

      session_token = get_session(mobile_conn, :user_token)
      %{value: signed_token} = mobile_conn.resp_cookies[@remember_me_cookie]

      conn =
        CoreWeb.ConnCase.build_conn()
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> put_req_header("user-agent", @mobile_user_agent)
        |> delete("/user/session")

      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == "/user/auth/identify?session_event=logged_out"
      refute Systems.Account.Public.get_user_by_session_token(session_token)
    end

    test "does not persist a desktop OTP session", %{conn: conn} do
      user = Factories.insert!(:member)
      token = Phoenix.Token.sign(Endpoint, @token_salt, %{user_id: user.id, email: user.email})

      conn = get(conn, ~p"/user/auth/redeem?token=#{token}")
      assert session_token = get_session(conn, :user_token)

      assert %{context: "session", last_used_at: nil} =
               Core.Repo.get_by(Systems.Account.UserTokenModel, token: session_token)

      refute conn.resp_cookies[@remember_me_cookie]
    end
  end

  describe "GET /user/auth/status" do
    test "returns no content for a valid mobile session without exposing credentials", %{
      conn: conn
    } do
      user = Factories.insert!(:member)
      token = Phoenix.Token.sign(Endpoint, @token_salt, %{user_id: user.id, email: user.email})

      mobile_conn =
        conn
        |> put_req_header("user-agent", @mobile_user_agent)
        |> get(~p"/user/auth/redeem?token=#{token}")

      %{value: signed_token} = mobile_conn.resp_cookies[@remember_me_cookie]

      conn =
        CoreWeb.ConnCase.build_conn()
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> get("/user/auth/status")

      assert response(conn, 204) == ""
      assert get_resp_header(conn, "cache-control") == ["no-store"]
    end

    test "returns unauthorized without a valid session", %{conn: conn} do
      conn = get(conn, "/user/auth/status")

      assert response(conn, 401) == ""
      assert get_resp_header(conn, "cache-control") == ["no-store"]
    end
  end

  describe "GET /user/auth/redeem — participant entry" do
    test "creates a participant account", %{conn: conn} do
      email = "participant-#{Faker.UUID.v4()}@example.com"

      token =
        Phoenix.Token.sign(Endpoint, @token_salt, %{
          user_id: nil,
          email: email,
          creator?: false,
          return_to: nil
        })

      _conn = get(conn, ~p"/user/auth/redeem?token=#{token}")

      refute Systems.Account.Public.get_user_by_email(email).creator
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

  describe "GET /user/auth/redeem — existing creator via participant entry" do
    test "retains the stored account type", %{conn: conn} do
      user = Factories.insert!(:member, %{creator: true})

      token =
        Phoenix.Token.sign(Endpoint, @token_salt, %{
          user_id: user.id,
          email: user.email,
          creator?: false,
          return_to: nil
        })

      _conn = get(conn, ~p"/user/auth/redeem?token=#{token}")

      assert Systems.Account.Public.get_user!(user.id).creator
    end
  end

  describe "AuthCodeVerifyPage.decode_redeem_token/1" do
    test "roundtrips :return_to alongside :user_id and :email" do
      payload = %{user_id: 42, email: "x@example.com", return_to: "/pool/panl/join"}
      token = Phoenix.Token.sign(Endpoint, @token_salt, payload)

      assert {:ok, ^payload} = AuthCodeVerifyPage.decode_redeem_token(token)
    end
  end

  describe "GET /user/auth/redeem — new email, provisional user in session" do
    # The affiliate → post-launch CTA journey. After the user finishes an
    # assignment they're already logged in as a provisional synth
    # Account.User (no password, no confirmed_at). Clicking "Join Panl"
    # sends them through auth. At redeem, the controller must link the
    # real email to that existing user — NOT register a fresh duplicate.
    setup %{conn: conn} do
      provisional_user =
        Factories.insert!(:member, %{
          email: "synth-#{Faker.UUID.v4()}@example.com",
          hashed_password: "no-password-set",
          confirmed_at: nil
        })

      token = Systems.Account.Public.generate_user_session_token(provisional_user)

      conn =
        conn
        |> Phoenix.ConnTest.init_test_session(%{})
        |> Plug.Conn.put_session(:user_token, token)

      %{conn: conn, provisional_user: provisional_user}
    end

    test "links the real email to the provisional user (no new user created)", %{
      conn: conn,
      provisional_user: provisional_user
    } do
      new_email = "real-#{Faker.UUID.v4()}@example.com"
      before_count = user_count()

      redeem_token =
        Phoenix.Token.sign(Endpoint, @token_salt, %{
          user_id: nil,
          email: new_email,
          return_to: "/pool/panl/join"
        })

      conn = get(conn, ~p"/user/auth/redeem?token=#{redeem_token}")

      assert redirected_to(conn) == "/pool/panl/join"
      assert user_count() == before_count

      updated_user = Systems.Account.Public.get_user!(provisional_user.id)
      assert updated_user.email == new_email
    end

    test "creates a satellite Systems.Account.Auth.Email record for the linked email", %{
      conn: conn,
      provisional_user: provisional_user
    } do
      new_email = "real-#{Faker.UUID.v4()}@example.com"
      refute Systems.Account.Auth.Email.get_by_user(provisional_user)

      redeem_token =
        Phoenix.Token.sign(Endpoint, @token_salt, %{
          user_id: nil,
          email: new_email,
          return_to: nil
        })

      _conn = get(conn, ~p"/user/auth/redeem?token=#{redeem_token}")

      assert Systems.Account.Auth.Email.get_by_user(provisional_user) != nil
    end
  end

  describe "GET /user/auth/redeem — new email, activated user in session" do
    # Guardrail: even if a fully-activated (non-provisional) user is
    # logged in when the redeem hits, we must NOT hijack their email.
    # Register a new user, as if there were no session.
    setup %{conn: conn} do
      activated_user = Factories.insert!(:member, %{creator: false})
      original_email = activated_user.email

      token = Systems.Account.Public.generate_user_session_token(activated_user)

      conn =
        conn
        |> Phoenix.ConnTest.init_test_session(%{})
        |> Plug.Conn.put_session(:user_token, token)

      %{conn: conn, activated_user: activated_user, original_email: original_email}
    end

    test "registers a new user and leaves the logged-in user's email untouched", %{
      conn: conn,
      activated_user: activated_user,
      original_email: original_email
    } do
      new_email = "real-#{Faker.UUID.v4()}@example.com"
      before_count = user_count()

      redeem_token =
        Phoenix.Token.sign(Endpoint, @token_salt, %{
          user_id: nil,
          email: new_email,
          return_to: nil
        })

      _conn = get(conn, ~p"/user/auth/redeem?token=#{redeem_token}")

      assert user_count() == before_count + 1

      assert Systems.Account.Public.get_user!(activated_user.id).email ==
               original_email
    end
  end

  defp user_count do
    import Ecto.Query
    Core.Repo.aggregate(from(u in Systems.Account.User), :count, :id)
  end
end
