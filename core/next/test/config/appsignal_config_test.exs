defmodule Next.Config.AppsignalConfigTest do
  # Replaces the process environment while runtime.exs is evaluated.
  use ExUnit.Case, async: false

  alias Mica.RuntimeConfig.Snapshot

  # The config a release gets: config.exs (with prod.exs) and runtime.exs
  # evaluated for the prod fixture with `overrides` merged on top.
  defp release_config(overrides \\ %{}) do
    env =
      "next/test/config/env/prod.env"
      |> Snapshot.read_env_file()
      |> Map.merge(overrides)

    Config.Reader.merge(
      Config.Reader.read!("config/config.exs", env: :prod, target: :host),
      Snapshot.evaluate("config/runtime.exs", env, :prod)
    )
  end

  test "the running app sends no request params to AppSignal" do
    assert Application.get_env(:appsignal, :config)[:send_params] == false
  end

  test "a release sends no request params to AppSignal" do
    assert release_config()[:appsignal][:config][:send_params] == false
  end

  test "refuses APPSIGNAL_SEND_PARAMS, which would override send_params" do
    assert_raise RuntimeError, ~r/APPSIGNAL_SEND_PARAMS/, fn ->
      release_config(%{"APPSIGNAL_SEND_PARAMS" => "true"})
    end
  end

  test "accepts APPSIGNAL_SEND_PARAMS=false" do
    config = release_config(%{"APPSIGNAL_SEND_PARAMS" => "false"})
    assert config[:appsignal][:config][:send_params] == false
  end

  test "the running app sends no session data to AppSignal" do
    assert Application.get_env(:appsignal, :config)[:send_session_data] == false
  end

  test "a release sends no session data to AppSignal" do
    assert release_config()[:appsignal][:config][:send_session_data] == false
  end

  test "refuses APPSIGNAL_SEND_SESSION_DATA, which would override send_session_data" do
    assert_raise RuntimeError, ~r/APPSIGNAL_SEND_SESSION_DATA/, fn ->
      release_config(%{"APPSIGNAL_SEND_SESSION_DATA" => "true"})
    end
  end

  test "accepts APPSIGNAL_SEND_SESSION_DATA=false" do
    config = release_config(%{"APPSIGNAL_SEND_SESSION_DATA" => "false"})
    assert config[:appsignal][:config][:send_session_data] == false
  end

  test "a release keeps the conn out of crash log metadata" do
    assert release_config()[:plug_cowboy][:conn_in_exception_metadata] == false
  end

  # AppSignal's logger handler sends a crash's log metadata as is, and plug_cowboy
  # puts the whole conn (params, cookie header, session) there unless told not to.
  test "a crashed request's log metadata carries no conn" do
    conn =
      Plug.Test.init_test_session(
        Plug.Test.conn(:get, "/a/sqid?p=participant-1"),
        %{panel_info: %{participant: "participant-1"}}
      )

    reason = {{%RuntimeError{message: "boom"}, []}, {NextWeb.Endpoint, :call, [conn, []]}}

    assert {:ok, _message, metadata} =
             Plug.Cowboy.Translator.translate(
               :error,
               :error,
               :format,
               {~c"Ranch listener NextWeb.Endpoint.HTTP terminated",
                [NextWeb.Endpoint.HTTP, self(), 1, self(), {reason, []}]}
             )

    refute Keyword.has_key?(metadata, :conn)
  end
end
