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
end
