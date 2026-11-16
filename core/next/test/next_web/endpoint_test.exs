defmodule NextWeb.EndpointTest do
  # Pins what a SaaS endpoint shares with the endpoint it replaced
  # (`MicaWeb.Endpoint`, `CoreWeb.Endpoint` before it): the session cookie, the
  # socket paths, the PubSub server and the telemetry prefix. Signed-in users,
  # connected LiveView clients and AppSignal's request metrics depend on them.
  use MicaWeb.ConnCase, async: false

  @session_options [store: :cookie, key: "_core_key", signing_salt: "3oh1/4M5"]
  @live_view_signing_salt "U46ENwad8CDswjwuXgNZVpJjUlBjbmL9"

  @endpoints [NextWeb.Endpoint, MicaSaasWeb.Endpoint]

  test "each SaaS names its own endpoint, and Mica reaches Next's" do
    assert Next.SaaS.endpoint() == NextWeb.Endpoint
    assert MicaSaas.SaaS.endpoint() == MicaSaasWeb.Endpoint
    assert Mica.SaaS.endpoint() == NextWeb.Endpoint
  end

  test "keeps the session options" do
    assert MicaWeb.Endpoint.session_options() == @session_options
  end

  for endpoint <- @endpoints do
    describe inspect(endpoint) do
      test "keeps the socket paths, with the session on the LiveView socket" do
        sockets =
          Map.new(unquote(endpoint).__sockets__(), fn {path, socket, opts} ->
            {path, {socket, opts}}
          end)

        assert sockets == %{
                 "/socket" => {Systems.Account.UserSocket, [websocket: true, longpoll: false]},
                 "/live" =>
                   {Phoenix.LiveView.Socket,
                    [websocket: [connect_info: [:user_agent, session: @session_options]]]}
               }
      end
    end
  end

  # Each SaaS configures its own endpoint, in its config file.
  @config_files %{
    NextWeb.Endpoint => "next/config/config.exs",
    MicaSaasWeb.Endpoint => "mica_saas/config/config.exs"
  }

  for endpoint <- @endpoints, env <- [:dev, :test, :prod] do
    test "#{inspect(endpoint)} keeps the PubSub server and the LiveView signing salt in #{env}" do
      config = endpoint_config(unquote(endpoint), unquote(env))
      assert config[:pubsub_server] == Mica.PubSub
      assert config[:live_view][:signing_salt] == @live_view_signing_salt
    end
  end

  for env <- [:dev, :test, :prod] do
    test "Next and Self configure their endpoints alike in #{env}" do
      # Inspected, so that the live-reload patterns compare by their source.
      assert inspect(endpoint_config(NextWeb.Endpoint, unquote(env))) ==
               inspect(endpoint_config(MicaSaasWeb.Endpoint, unquote(env)))
    end
  end

  test "reads a session cookie written with the pinned options", %{conn: conn} do
    conn =
      conn
      |> put_req_cookie("_core_key", pinned_session_cookie(%{"pin" => "kept"}))
      |> get("/user/signin")

    assert get_session(conn, "pin") == "kept"
  end

  test "writes its session cookie with the pinned options", %{conn: conn} do
    conn = get(conn, "/user/signin")
    assert %{"_core_key" => %{value: cookie}} = conn.resp_cookies

    assert %{"_csrf_token" => _} = read_pinned_session_cookie(cookie)
  end

  test "reports requests under the [:phoenix, :endpoint] telemetry prefix", %{conn: conn} do
    test_pid = self()
    handler = "endpoint-test-#{inspect(test_pid)}"

    :telemetry.attach(
      handler,
      [:phoenix, :endpoint, :stop],
      fn _event, _measurements, %{conn: conn}, _config ->
        send(test_pid, {:endpoint_stop, conn.request_path})
      end,
      nil
    )

    on_exit(fn -> :telemetry.detach(handler) end)

    get(conn, "/user/signin")
    assert_receive {:endpoint_stop, "/user/signin"}
  end

  defp endpoint_config(endpoint, env),
    do: Config.Reader.read!(@config_files[endpoint], env: env)[:mica][endpoint]

  # A cookie as the old endpoint wrote it: Plug.Session with the pinned options
  # and the shared secret key base.
  defp pinned_session_cookie(session) do
    conn =
      Enum.reduce(session, session_conn(), fn {key, value}, conn ->
        Plug.Conn.put_session(conn, key, value)
      end)
      |> Plug.Conn.send_resp(200, "")

    conn.resp_cookies["_core_key"].value
  end

  defp read_pinned_session_cookie(cookie) do
    session_conn(%{"_core_key" => cookie}) |> Plug.Conn.get_session()
  end

  defp session_conn(cookies \\ %{}) do
    conn =
      Enum.reduce(cookies, Plug.Test.conn(:get, "/"), fn {key, value}, conn ->
        Plug.Test.put_req_cookie(conn, key, value)
      end)

    %{conn | secret_key_base: NextWeb.Endpoint.config(:secret_key_base)}
    |> Plug.Session.call(Plug.Session.init(@session_options))
    |> Plug.Conn.fetch_session()
  end
end
