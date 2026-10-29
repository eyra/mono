defmodule Next.Account.NativeSigninControllerTest do
  use CoreWeb.ConnCase, async: false
  use Core.FeatureFlags.Test
  use Bamboo.Test

  alias Core.Repo
  alias Systems.Account
  alias Systems.Account.AuthCodeModel

  @remember_me_cookie "_core_web_user_remember_me"
  @mobile_user_agent "Mozilla/5.0 (iPhone; CPU iPhone OS 18_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 NextApp/0.1.0 iOS"
  @browser_user_agent "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.6 Safari/605.1.15"

  setup %{conn: conn} do
    set_feature_flag(:otp, true)

    conn =
      conn
      |> put_req_header("user-agent", @mobile_user_agent)
      |> put_req_header("origin", "https://eyra.co")
      |> put_req_header("sec-fetch-site", "same-origin")
      |> put_req_header("content-type", "application/json")

    %{conn: conn}
  end

  describe "POST /user/auth/native/identify" do
    test "sends a code to an unknown email", %{conn: conn} do
      email = unique_email("new")

      conn = post_json(conn, "/user/auth/native/identify", %{email: " #{email} "})

      assert json_response(conn, 200) == %{"next" => "code"}
      assert get_resp_header(conn, "cache-control") == ["no-store"]
      assert Repo.one(AuthCodeModel.active_query(email))
      assert_email_delivered_with(to: [nil: email])
    end

    test "sends a code to an existing email the same way", %{conn: conn} do
      user = Factories.insert!(:member)

      conn = post_json(conn, "/user/auth/native/identify", %{email: user.email})

      assert json_response(conn, 200) == %{"next" => "code"}
      assert %{user_id: user_id} = Repo.one(AuthCodeModel.active_query(user.email))
      assert user_id == user.id
    end

    test "rejects an invalid email", %{conn: conn} do
      conn = post_json(conn, "/user/auth/native/identify", %{email: "not-an-email"})

      assert json_response(conn, 422) == %{"error" => "invalid_email"}
    end

    test "rejects a request without an email", %{conn: conn} do
      conn = post_json(conn, "/user/auth/native/identify", %{})

      assert json_response(conn, 400) == %{"error" => "invalid_request"}
    end

    test "applies the per-email rate limit", %{conn: conn} do
      email = unique_email("limited")

      for _ <- 1..3 do
        assert %{"next" => "code"} =
                 conn
                 |> post_json("/user/auth/native/identify", %{email: email})
                 |> json_response(200)
      end

      conn = post_json(conn, "/user/auth/native/identify", %{email: email})

      assert json_response(conn, 429) == %{"error" => "rate_limited"}
    end

    test "sends an identity provider user to the provider's web sign-in", %{conn: conn} do
      with_auth_methods(%{google: %{provider: true, satellite: true, mx_provider: "google"}})
      user = Factories.insert!(:member, %{email: unique_email("google")})

      %Account.Auth.Google.UserModel{}
      |> Account.Auth.Google.UserModel.changeset(%{sub: "native-google-sub"})
      |> Ecto.Changeset.put_assoc(:user, user)
      |> Repo.insert!()

      conn =
        post_json(conn, "/user/auth/native/identify", %{
          email: user.email,
          return_to: "/assignment/1"
        })

      assert json_response(conn, 200) == %{
               "next" => "identity_provider",
               "provider" => "google",
               "url" =>
                 "/auth/google?login_hint=#{URI.encode_www_form(user.email)}&return_to=%2Fassignment%2F1"
             }

      refute Repo.one(AuthCodeModel.active_query(user.email))
    end

    test "refuses an account that only signs in through Centerdata", %{conn: conn} do
      with_auth_methods(%{centerdata: %{provider: true, satellite: true}})
      user = Factories.insert!(:member, %{email: unique_email("centerdata")})

      %Account.Auth.Centerdata.UserModel{}
      |> Account.Auth.Centerdata.UserModel.changeset(%{
        "email" => user.email,
        "sub" => "native-centerdata-sub"
      })
      |> Ecto.Changeset.put_assoc(:user, user)
      |> Repo.insert!()

      conn = post_json(conn, "/user/auth/native/identify", %{email: user.email})

      assert json_response(conn, 422) == %{"error" => "unsupported_account"}
      refute Repo.one(AuthCodeModel.active_query(user.email))
    end

    test "is unavailable while OTP sign-in is off", %{conn: conn} do
      set_feature_flag(:otp, false)

      conn = post_json(conn, "/user/auth/native/identify", %{email: unique_email("off")})

      assert json_response(conn, 404) == %{"error" => "unavailable"}
    end
  end

  describe "POST /user/auth/native/verify" do
    test "signs in an existing user with a mobile session", %{conn: conn} do
      user = Factories.insert!(:member)
      code = issue_code(user.email, user.id)

      conn = post_json(conn, "/user/auth/native/verify", %{email: user.email, code: code})

      assert json_response(conn, 200) == %{"onboarding" => false, "redirect_to" => nil}
      assert get_resp_header(conn, "cache-control") == ["no-store"]

      session_token = get_session(conn, :user_token)

      assert %{context: "mobile_session", user_id: user_id} =
               Repo.get_by(Account.UserTokenModel, token: session_token)

      assert user_id == user.id

      assert %{max_age: 5_184_000, http_only: true, same_site: "Lax"} =
               conn.resp_cookies[@remember_me_cookie]

      refute conn.resp_body =~ Base.url_encode64(session_token)
      refute Repo.one(AuthCodeModel.active_query(user.email))
    end

    test "the session cookie it sets signs in /user/auth/status and the web Account page", %{
      conn: conn
    } do
      user = Factories.insert!(:member)
      code = issue_code(user.email, user.id)

      verify_conn = post_json(conn, "/user/auth/native/verify", %{email: user.email, code: code})
      %{value: signed_token} = verify_conn.resp_cookies[@remember_me_cookie]

      status_conn =
        CoreWeb.ConnCase.build_conn()
        |> put_req_header("user-agent", @mobile_user_agent)
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> get("/user/auth/status")

      assert response(status_conn, 204) == ""

      account_conn =
        CoreWeb.ConnCase.build_conn()
        |> put_req_header("user-agent", @mobile_user_agent)
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> get("/user/account")

      assert html_response(account_conn, 200)
    end

    test "registers a new email as a participant who still needs onboarding", %{conn: conn} do
      email = unique_email("fresh")
      code = issue_code(email, nil)

      conn = post_json(conn, "/user/auth/native/verify", %{email: email, code: code})

      assert json_response(conn, 200) == %{
               "onboarding" => true,
               "redirect_to" => "/user/onboarding"
             }

      assert %{creator: false} = Account.Public.get_user_by_email(email)
      assert conn.resp_cookies[@remember_me_cookie]
    end

    test "signs out a restricted session first, like the web flow", %{conn: conn} do
      {:ok, external_user} =
        Account.Auth.External.register_user(:org, "native-#{System.unique_integer([:positive])}")

      {:ok, conn: conn, user: _} = login(external_user, %{conn: conn})

      email = unique_email("after-external")

      conn =
        post_json(conn, "/user/auth/native/verify", %{email: email, code: issue_code(email, nil)})

      assert %{"onboarding" => true} = json_response(conn, 200)
      assert %{id: new_user_id} = Account.Public.get_user_by_email(email)
      assert new_user_id != external_user.id
      assert Account.Public.get_user!(external_user.id).email == external_user.email
    end

    test "carries return_to into onboarding for a new user", %{conn: conn} do
      email = unique_email("fresh-return")
      code = issue_code(email, nil)

      conn =
        post_json(conn, "/user/auth/native/verify", %{
          email: email,
          code: code,
          return_to: "/assignment/1/invite"
        })

      assert %{"redirect_to" => "/user/onboarding?return_to=%2Fassignment%2F1%2Finvite"} =
               json_response(conn, 200)
    end

    test "returns a sanitized return_to for an existing user", %{conn: conn} do
      user = Factories.insert!(:member)

      conn_with_path =
        post_json(conn, "/user/auth/native/verify", %{
          email: user.email,
          code: issue_code(user.email, user.id),
          return_to: "/assignment/1"
        })

      assert %{"redirect_to" => "/assignment/1"} = json_response(conn_with_path, 200)

      conn_with_url =
        post_json(conn, "/user/auth/native/verify", %{
          email: user.email,
          code: issue_code(user.email, user.id),
          return_to: "https://evil.example"
        })

      assert %{"redirect_to" => nil} = json_response(conn_with_url, 200)
    end

    test "return_to accepts only same-site paths", %{conn: conn} do
      user = Factories.insert!(:member)

      for return_to <- ["//example.org/x", "/\\example.org"] do
        conn =
          post_json(conn, "/user/auth/native/verify", %{
            email: user.email,
            code: issue_code(user.email, user.id),
            return_to: return_to
          })

        assert %{"redirect_to" => nil} = json_response(conn, 200)
      end

      email = unique_email("fresh-same-site")

      conn =
        post_json(conn, "/user/auth/native/verify", %{
          email: email,
          code: issue_code(email, nil),
          return_to: "//example.org/x"
        })

      assert %{"redirect_to" => "/user/onboarding"} = json_response(conn, 200)
    end

    test "rejects a wrong code and counts the attempt", %{conn: conn} do
      user = Factories.insert!(:member)
      code = issue_code(user.email, user.id)

      conn = post_json(conn, "/user/auth/native/verify", %{email: user.email, code: wrong(code)})

      assert json_response(conn, 422) == %{"error" => "invalid_code"}
      assert %{attempts: 1} = Repo.one(AuthCodeModel.active_query(user.email))
      refute conn.resp_cookies[@remember_me_cookie]
      refute get_session(conn, :user_token)
    end

    test "rejects an expired code", %{conn: conn} do
      user = Factories.insert!(:member)
      code = issue_code(user.email, user.id)

      expired_at =
        NaiveDateTime.utc_now() |> NaiveDateTime.add(-11 * 60) |> NaiveDateTime.truncate(:second)

      Repo.update_all(AuthCodeModel, set: [inserted_at: expired_at])

      conn = post_json(conn, "/user/auth/native/verify", %{email: user.email, code: code})

      assert json_response(conn, 422) == %{"error" => "code_expired"}
    end

    test "rejects a code for an email without one", %{conn: conn} do
      conn =
        post_json(conn, "/user/auth/native/verify", %{email: unique_email("none"), code: "123456"})

      assert json_response(conn, 422) == %{"error" => "code_expired"}
    end

    test "stops after too many attempts, even with the right code", %{conn: conn} do
      user = Factories.insert!(:member)
      code = issue_code(user.email, user.id, attempts: 5)

      conn = post_json(conn, "/user/auth/native/verify", %{email: user.email, code: code})

      assert json_response(conn, 422) == %{"error" => "too_many_attempts"}
      refute conn.resp_cookies[@remember_me_cookie]
    end

    test "rejects a request without a code", %{conn: conn} do
      conn = post_json(conn, "/user/auth/native/verify", %{email: unique_email("no-code")})

      assert json_response(conn, 400) == %{"error" => "invalid_request"}
    end
  end

  describe "malformed body" do
    test "a body that is not JSON gets a plain 400", %{conn: conn} do
      conn = put_req_header(conn, "accept", "application/json")

      assert {400, _headers, body} =
               assert_error_sent(400, fn ->
                 post(conn, "/user/auth/native/identify", "{not json")
               end)

      assert Jason.decode!(body) == %{"error" => "Bad Request"}
    end
  end

  describe "CSRF and client checks" do
    test "rejects a cross-origin request", %{conn: conn} do
      conn =
        conn
        |> put_req_header("origin", "https://evil.example")
        |> post_json("/user/auth/native/identify", %{email: unique_email("csrf")})

      assert json_response(conn, 403) == %{"error" => "forbidden"}
    end

    test "rejects a request without an Origin header", %{conn: conn} do
      conn =
        conn
        |> delete_req_header("origin")
        |> post_json("/user/auth/native/identify", %{email: unique_email("csrf")})

      assert json_response(conn, 403) == %{"error" => "forbidden"}
    end

    test "rejects a cross-site fetch", %{conn: conn} do
      conn =
        conn
        |> put_req_header("sec-fetch-site", "cross-site")
        |> post_json("/user/auth/native/identify", %{email: unique_email("csrf")})

      assert json_response(conn, 403) == %{"error" => "forbidden"}
    end

    test "rejects a form post, so a cross-site form cannot sign anyone in", %{conn: conn} do
      user = Factories.insert!(:member)
      code = issue_code(user.email, user.id)

      conn =
        conn
        |> put_req_header("content-type", "application/x-www-form-urlencoded")
        |> post("/user/auth/native/verify", URI.encode_query(%{email: user.email, code: code}))

      assert json_response(conn, 415) == %{"error" => "unsupported_media_type"}
      refute conn.resp_cookies[@remember_me_cookie]
      assert Repo.one(AuthCodeModel.active_query(user.email))
    end

    test "rejects a browser outside the Next app", %{conn: conn} do
      user = Factories.insert!(:member)
      code = issue_code(user.email, user.id)

      conn =
        conn
        |> put_req_header("user-agent", @browser_user_agent)
        |> post_json("/user/auth/native/verify", %{email: user.email, code: code})

      assert json_response(conn, 403) == %{"error" => "unsupported_client"}
      refute conn.resp_cookies[@remember_me_cookie]
    end
  end

  defp post_json(conn, path, body), do: post(conn, path, Jason.encode!(body))

  defp issue_code(email, user_id, opts \\ []) do
    {code, auth_code} = AuthCodeModel.build(email, user_id)
    Repo.insert!(%{auth_code | attempts: Keyword.get(opts, :attempts, 0)})
    code
  end

  defp wrong(code), do: if(code == "123456", do: "654321", else: "123456")

  defp unique_email(prefix), do: "#{prefix}-#{System.unique_integer([:positive])}@example.com"

  defp with_auth_methods(auth_methods) do
    account = Application.get_env(:core, :account, [])
    original = Keyword.fetch!(account, :auth_methods)
    Application.put_env(:core, :account, Keyword.put(account, :auth_methods, auth_methods))

    on_exit(fn ->
      account = Application.get_env(:core, :account, [])
      Application.put_env(:core, :account, Keyword.put(account, :auth_methods, original))
    end)
  end
end
