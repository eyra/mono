defmodule Next.Account.NativeHandoffTest.FakeGoogle do
  def authorize_url(config),
    do: {:ok, %{url: Keyword.fetch!(config, :site), session_params: %{state: "test-state"}}}

  def callback(config, _params), do: Keyword.fetch!(config, :result)
end

defmodule Next.Account.NativeHandoffTest.FakeOIDC do
  def authorize_url(config),
    do:
      {:ok,
       %{
         url: Keyword.fetch!(config, :base_url),
         session_params: %{state: "test-state", nonce: config[:nonce]}
       }}

  def callback(config, _params), do: {:ok, %{user: config[:userinfo], token: "test-token"}}
  def fetch_userinfo(config, "test-token"), do: {:ok, config[:userinfo]}
end

defmodule Next.Account.NativeHandoffTest do
  use CoreWeb.ConnCase, async: false
  use Core.FeatureFlags.Test

  import Ecto.Query, only: [from: 2]

  alias Core.Repo
  alias CoreWeb.Endpoint
  alias Next.Account.NativeHandoffTest.FakeGoogle
  alias Next.Account.NativeHandoffTest.FakeOIDC
  alias Systems.Account

  @cookie "_next_native_sign_in"
  @remember_me_cookie "_core_web_user_remember_me"
  @mobile_user_agent "Mozilla/5.0 (iPhone; CPU iPhone OS 26_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 NextApp/0.1.0 iOS"
  @code_verifier "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"

  setup do
    with_auth_methods(%{
      google: %{provider: true, satellite: true, mx_provider: "google"},
      surfconext: %{provider: true, satellite: true},
      centerdata: %{provider: true, satellite: true},
      email: %{provider: false, satellite: true},
      mock: %{provider: true, satellite: false}
    })

    set_feature_flag(:member_google_sign_in, true)
    set_feature_flag(:centerdata_sign_in, true)
    :ok
  end

  describe "GET /user/auth/native/provider/:provider" do
    test "marks the sheet and continues at Core's start of the provider", %{conn: conn} do
      conn = start(conn, "google", login_hint: "jane@gmail.com", return_to: "/assignment/1")

      assert redirected_to(conn) == "/auth/google?login_hint=jane%40gmail.com"
      assert %{max_age: 600, http_only: true, same_site: "Lax"} = conn.resp_cookies[@cookie]
    end

    test "starts SURFconext, Centerdata and the mock provider", %{conn: conn} do
      assert redirected_to(start(conn, "surfconext")) == "/auth/surfconext"
      assert redirected_to(start(conn, "centerdata")) == "/auth/centerdata"

      assert redirected_to(start(conn, "mock", login_hint: "jane@mock.com")) ==
               "/auth/mock/callback?email=jane%40mock.com"
    end

    test "sends an unknown provider back to the app", %{conn: conn} do
      conn = start(conn, "apple")

      assert_app_callback(conn, error: "invalid_request")
      refute conn.resp_cookies[@cookie][:value]
    end

    test "sends a missing or malformed challenge back to the app", %{conn: conn} do
      assert_app_callback(start(conn, "google", code_challenge: "short"),
        error: "invalid_request"
      )

      assert_app_callback(start(conn, "google", code_challenge_method: "plain"),
        error: "invalid_request"
      )

      assert_app_callback(get(conn, "/user/auth/native/provider/google"),
        error: "invalid_request"
      )
    end

    test "sends a provider that is off back to the app", %{conn: conn} do
      set_feature_flag(:centerdata_sign_in, false)
      assert_app_callback(start(conn, "centerdata"), error: "unavailable")

      set_feature_flag(:member_google_sign_in, false)
      assert_app_callback(start(conn, "google"), error: "unavailable")
    end
  end

  describe "the provider callback in a marked sheet" do
    test "Google: hands the sign-in to the app instead of starting a session", %{conn: conn} do
      email = unique_email("google")
      with_google_result({:ok, %{user: google_userinfo(email), token: "test-token"}})

      conn = start(conn, "google", login_hint: email, return_to: "/assignment/1")
      conn = conn |> recycle() |> get("/auth/google?login_hint=#{email}")
      callback_conn = conn |> recycle() |> get("/auth/google/callback?code=test&state=test-state")

      token = assert_app_callback(callback_conn, :token)
      refute get_session(callback_conn, :user_token)
      refute callback_conn.resp_cookies[@remember_me_cookie]
      assert %{max_age: 0} = callback_conn.resp_cookies[@cookie]

      redeem_conn = redeem(token, @code_verifier)

      assert json_response(redeem_conn, 200) == %{
               "onboarding" => true,
               "redirect_to" => "/user/onboarding?return_to=%2Fassignment%2F1"
             }

      assert %{id: user_id} = Account.Public.get_user_by_email(email)
      assert_mobile_session(redeem_conn, user_id)
    end

    test "SURFconext: hands an existing user to the app", %{conn: conn} do
      email = unique_email("surf")
      userinfo = surf_userinfo(email)

      with_oidc(Account.Auth.Surfconext,
        base_url: "https://connect.test.surf",
        userinfo: userinfo
      )

      {:ok, %{user: user}} = Account.Auth.authenticate(Account.Auth.Surfconext, userinfo)

      conn = start(conn, "surfconext", return_to: "/assignment/2")
      conn = conn |> recycle() |> get("/auth/surfconext")
      callback_conn = conn |> recycle() |> get("/auth/surfconext/callback?code=test")

      redeem_conn = callback_conn |> assert_app_callback(:token) |> redeem(@code_verifier)

      assert json_response(redeem_conn, 200) == %{
               "onboarding" => false,
               "redirect_to" => "/assignment/2"
             }

      assert_mobile_session(redeem_conn, user.id)
    end

    test "Centerdata: hands a new user to the app", %{conn: conn} do
      email = unique_email("panel")

      with_oidc(Account.Auth.Centerdata,
        base_url: "https://messpanel.test.centerdata.nl",
        userinfo: %{"sub" => "native-1", "email" => email, "email_verified" => true}
      )

      conn = start(conn, "centerdata")
      conn = conn |> recycle() |> get("/auth/centerdata")
      callback_conn = conn |> recycle() |> get("/auth/centerdata/callback?code=test")

      redeem_conn = callback_conn |> assert_app_callback(:token) |> redeem(@code_verifier)

      assert json_response(redeem_conn, 200) == %{
               "onboarding" => true,
               "redirect_to" => "/user/onboarding"
             }

      assert %{id: user_id} = Account.Public.get_user_by_email(email)
      assert_mobile_session(redeem_conn, user_id)
    end

    test "an account moved to the provider is handed over after the user confirms", %{
      conn: conn
    } do
      user = Factories.insert!(:member, %{email: unique_email("mock-existing", "mock.com")})

      conn = start(conn, "mock", login_hint: user.email)
      conn = conn |> recycle() |> get("/auth/mock/callback?email=#{user.email}")
      assert redirected_to(conn) == "/auth/mock/transfer"

      confirm_conn = conn |> recycle() |> post("/auth/mock/transfer/confirm")

      redeem_conn = confirm_conn |> assert_app_callback(:token) |> redeem(@code_verifier)

      assert %{"onboarding" => false} = json_response(redeem_conn, 200)
      assert_mobile_session(redeem_conn, user.id)
    end

    test "declining to move the account sends `cancelled` to the app", %{conn: conn} do
      user = Factories.insert!(:member, %{email: unique_email("mock-decline", "mock.com")})

      conn = start(conn, "mock", login_hint: user.email)
      conn = conn |> recycle() |> get("/auth/mock/callback?email=#{user.email}")
      conn = conn |> recycle() |> post("/auth/mock/transfer/decline")
      assert redirected_to(conn) == "/user/auth/identify"

      conn = conn |> recycle() |> get("/user/auth/identify")

      assert_app_callback(conn, error: "cancelled")
      assert %{max_age: 0} = conn.resp_cookies[@cookie]
    end

    test "a failed provider callback sends `failed` to the app", %{conn: conn} do
      conn = start(conn, "surfconext")
      # No provider state in the session: the callback fails like an expired attempt.
      conn = conn |> recycle() |> get("/auth/surfconext/callback?code=test")
      assert redirected_to(conn) == "/user/signin"

      conn = conn |> recycle() |> get("/user/signin")

      assert_app_callback(conn, error: "failed")
    end
  end

  describe "POST /user/auth/native/redeem" do
    setup %{conn: conn} do
      email = unique_email("redeem", "mock.com")
      conn = start(conn, "mock", login_hint: email)
      callback_conn = conn |> recycle() |> get("/auth/mock/callback?email=#{email}")
      %{token: assert_app_callback(callback_conn, :token)}
    end

    test "the session it sets signs in /user/auth/status", %{token: token} do
      redeem_conn = redeem(token, @code_verifier)
      assert %{value: signed_token} = redeem_conn.resp_cookies[@remember_me_cookie]

      status_conn =
        CoreWeb.ConnCase.build_conn()
        |> put_req_header("user-agent", @mobile_user_agent)
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> get("/user/auth/status")

      assert response(status_conn, 204) == ""
    end

    test "a token works once", %{token: token} do
      assert json_response(redeem(token, @code_verifier), 200)

      used = redeem(token, @code_verifier)
      assert json_response(used, 422) == %{"error" => "token_used"}
      refute used.resp_cookies[@remember_me_cookie]
    end

    test "a wrong verifier is refused and uses the token up", %{token: token} do
      wrong = redeem(token, String.duplicate("a", 43))

      assert json_response(wrong, 422) == %{"error" => "verifier_mismatch"}
      refute wrong.resp_cookies[@remember_me_cookie]
      refute get_session(wrong, :user_token)

      assert json_response(redeem(token, @code_verifier), 422) == %{"error" => "token_used"}
    end

    test "a token older than two minutes has expired", %{token: token} do
      {:ok, payload} = Phoenix.Token.decrypt(Endpoint, "native-sign-in", token)
      signed_at = System.system_time(:second) - 121
      old_token = Phoenix.Token.encrypt(Endpoint, "native-sign-in", payload, signed_at: signed_at)

      assert json_response(redeem(old_token, @code_verifier), 422) == %{
               "error" => "token_expired"
             }
    end

    test "a token whose stored half is older than two minutes counts as used", %{token: token} do
      old = NaiveDateTime.utc_now() |> NaiveDateTime.add(-121) |> NaiveDateTime.truncate(:second)

      Repo.update_all(from(t in Account.UserTokenModel, where: t.context == "native_sign_in"),
        set: [inserted_at: old]
      )

      assert json_response(redeem(token, @code_verifier), 422) == %{"error" => "token_used"}
    end

    test "rejects a token it did not issue and a request without one" do
      assert json_response(redeem("not-a-token", @code_verifier), 422) == %{
               "error" => "invalid_token"
             }

      assert json_response(post_json(native_conn(), "/user/auth/native/redeem", %{}), 400) == %{
               "error" => "invalid_request"
             }
    end

    test "is only open to same-origin JSON calls of the app", %{token: token} do
      conn =
        native_conn()
        |> put_req_header("origin", "https://evil.example")
        |> post_json("/user/auth/native/redeem", %{token: token, code_verifier: @code_verifier})

      assert json_response(conn, 403) == %{"error" => "forbidden"}
    end
  end

  describe "the web sign-in" do
    test "an identity-provider sign-in without a marked sheet starts a session as before", %{
      conn: conn
    } do
      email = unique_email("web")
      with_google_result({:ok, %{user: google_userinfo(email), token: "test-token"}})

      conn = get(conn, "/auth/google?return_to=/assignment/3")
      conn = conn |> recycle() |> get("/auth/google/callback?code=test&state=test-state")

      assert redirected_to(conn) == "/user/onboarding?return_to=%2Fassignment%2F3"
      assert get_session(conn, :user_token)
      refute Repo.exists?(from(t in Account.UserTokenModel, where: t.context == "native_sign_in"))
    end

    test "the sign-in pages render as before", %{conn: conn} do
      assert html_response(get(conn, "/user/signin"), 200)
      assert html_response(get(conn, "/user/auth/identify"), 200)
    end

    test "the callback URL sends a browser that opens it to the sign-in page", %{conn: conn} do
      assert redirected_to(get(conn, "/user/auth/native/callback?token=x")) == "/user/signin"
    end
  end

  describe "apple-app-site-association" do
    test "lets the apps catch the callback URL in the sign-in sheet", %{conn: conn} do
      assert %{"webcredentials" => %{"apps" => apps}} =
               conn |> get("/.well-known/apple-app-site-association") |> json_response(200)

      assert "XNWQJGGM96.co.eyra.next" in apps
      assert "XNWQJGGM96.co.eyra.next.dev" in apps
    end
  end

  defp start(conn, provider, opts \\ []) do
    query =
      [
        code_challenge: Keyword.get(opts, :code_challenge, code_challenge(@code_verifier)),
        code_challenge_method: Keyword.get(opts, :code_challenge_method, "S256"),
        login_hint: opts[:login_hint],
        return_to: opts[:return_to]
      ]
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)

    get(conn, "/user/auth/native/provider/#{provider}?#{URI.encode_query(query)}")
  end

  defp redeem(token, code_verifier) do
    post_json(native_conn(), "/user/auth/native/redeem", %{
      token: token,
      code_verifier: code_verifier
    })
  end

  defp native_conn do
    CoreWeb.ConnCase.build_conn()
    |> put_req_header("user-agent", @mobile_user_agent)
    |> put_req_header("origin", "https://eyra.co")
    |> put_req_header("sec-fetch-site", "same-origin")
    |> put_req_header("content-type", "application/json")
  end

  defp post_json(conn, path, body), do: post(conn, path, Jason.encode!(body))

  defp assert_app_callback(conn, :token) do
    %{"token" => token} = app_callback_params(conn)
    token
  end

  defp assert_app_callback(conn, error: error) do
    assert app_callback_params(conn) == %{"error" => error}
  end

  defp app_callback_params(conn) do
    location = redirected_to(conn)
    assert %URI{path: "/user/auth/native/callback", query: query} = URI.parse(location)
    assert String.starts_with?(location, Endpoint.url())
    assert get_resp_header(conn, "cache-control") == ["no-store"]
    URI.decode_query(query)
  end

  defp assert_mobile_session(conn, user_id) do
    assert %{context: "mobile_session", user_id: ^user_id} =
             Repo.get_by(Account.UserTokenModel, token: get_session(conn, :user_token))

    assert conn.resp_cookies[@remember_me_cookie]
  end

  defp code_challenge(verifier),
    do: :crypto.hash(:sha256, verifier) |> Base.url_encode64(padding: false)

  defp google_userinfo(email) do
    %{
      "sub" => "native-#{System.unique_integer([:positive])}",
      "email" => email,
      "email_verified" => true,
      "given_name" => "Jane",
      "family_name" => "Doe"
    }
  end

  defp surf_userinfo(email) do
    %{
      "sub" => "native-#{System.unique_integer([:positive])}",
      "email" => email,
      "email_verified" => true,
      "given_name" => "Jane",
      "family_name" => "Doe",
      "preferred_username" => "Jane Doe"
    }
  end

  defp with_google_result(result) do
    put_config(Account.Auth.Google,
      client_id: "test-client",
      client_secret: "test-secret",
      site: "https://accounts.test.google",
      redirect_uri: "http://localhost/auth/google/callback",
      google_module: FakeGoogle,
      result: result
    )
  end

  defp with_oidc(provider, config) do
    put_config(
      provider,
      [
        client_id: "test-client",
        client_secret: "test-secret",
        redirect_uri: "http://localhost/callback",
        oidc_module: FakeOIDC
      ] ++ config
    )
  end

  defp put_config(key, config) do
    original = Application.get_env(:core, key)
    Application.put_env(:core, key, config)
    on_exit(fn -> restore_env(key, original) end)
  end

  defp restore_env(key, nil), do: Application.delete_env(:core, key)
  defp restore_env(key, original), do: Application.put_env(:core, key, original)

  defp unique_email(prefix, domain \\ "example.com"),
    do: "#{prefix}-#{System.unique_integer([:positive])}@#{domain}"

  defp with_auth_methods(auth_methods) do
    account = Application.get_env(:core, :account, [])
    put_config(:account, Keyword.put(account, :auth_methods, auth_methods))
  end
end
