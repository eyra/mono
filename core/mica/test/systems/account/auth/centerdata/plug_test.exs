defmodule Systems.Account.Auth.Centerdata.FakeOIDC do
  def authorize_url(config),
    do:
      {:ok,
       %{url: config[:base_url], session_params: %{state: "test-state", nonce: config[:nonce]}}}

  def callback(config, _params), do: {:ok, %{user: config[:userinfo]}}
end

defmodule Systems.Account.Auth.Centerdata.PlugTest do
  use CoreWeb.ConnCase, async: false

  alias Systems.Account.Auth.Centerdata.AuthorizePlug

  setup do
    original = Application.get_env(:core, Systems.Account.Auth.Centerdata, [])

    config = [
      client_id: "test-client",
      client_secret: "test-secret",
      base_url: "https://messpanel.test.centerdata.nl",
      redirect_uri: "http://localhost/auth/centerdata/callback",
      oidc_module: Systems.Account.Auth.Centerdata.FakeOIDC,
      userinfo: %{"sub" => "-1", "email" => "panel@example.com", "email_verified" => true}
    ]

    Application.put_env(:core, Systems.Account.Auth.Centerdata, config)
    on_exit(fn -> Application.put_env(:core, Systems.Account.Auth.Centerdata, original) end)
    {:ok, config: config}
  end

  test "starts a Centerdata OIDC sign-in", %{config: config} do
    conn =
      Plug.Test.conn(:get, "/auth/centerdata")
      |> init_test_session(%{})
      |> AuthorizePlug.call(:core)

    assert %{state: "test-state", nonce: nonce} = conn.private.plug_session["centerdata"]
    assert is_binary(nonce)
    assert redirected_to(conn) == config[:base_url]
  end

  test "is unavailable when the feature is disabled", %{conn: conn} do
    features = Application.fetch_env!(:core, :features)
    Application.put_env(:core, :features, Keyword.put(features, :centerdata_sign_in, false))
    on_exit(fn -> Application.put_env(:core, :features, features) end)

    conn = get(conn, "/auth/centerdata")

    assert conn.status == 404
  end

  test "creates an account from verified ID token claims", %{conn: conn} do
    conn =
      conn
      |> init_test_session(%{centerdata: %{state: "test-state", nonce: "test-nonce"}})
      |> get("/auth/centerdata/callback?code=test&state=test-state")

    assert redirected_to(conn) == "/user/onboarding"
    assert Systems.Account.Public.get_user_by_email("panel@example.com")
  end

  test "rejects an unverified ID token email", %{conn: conn, config: config} do
    Application.put_env(
      :core,
      Systems.Account.Auth.Centerdata,
      Keyword.put(config, :userinfo, %{
        "sub" => "-1",
        "email" => "panel@example.com",
        "email_verified" => false
      })
    )

    conn =
      conn
      |> init_test_session(%{centerdata: %{state: "test-state", nonce: "test-nonce"}})
      |> get("/auth/centerdata/callback?code=test&state=test-state")

    assert redirected_to(conn) == "/user/signin"
    refute Systems.Account.Public.get_user_by_email("panel@example.com")
  end
end
