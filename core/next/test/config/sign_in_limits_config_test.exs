defmodule Next.Config.SignInLimitsConfigTest do
  # Replaces the process environment while runtime.exs is evaluated.
  use ExUnit.Case, async: false

  alias Mica.RuntimeConfig
  alias Mix.Tasks.Config.Snapshot

  defp runtime_config(env) do
    %{env_file: env_file} = Enum.find(Snapshot.fixtures(), &(&1.name == "prod"))

    env_file
    |> RuntimeConfig.Snapshot.read_env_file()
    |> Map.merge(env)
    |> then(&RuntimeConfig.Snapshot.evaluate("config/runtime.exs", &1, :prod))
    |> Keyword.fetch!(:mica)
  end

  test "a release without AUTH_CODE_LIMITS and TRUSTED_PROXIES keeps the defaults" do
    config = runtime_config(%{})

    refute Keyword.has_key?(config, :auth_code_limits)
    refute Keyword.has_key?(config, MicaWeb.Plug.RemoteIp)
  end

  test "a release reads its sign-in code limits from AUTH_CODE_LIMITS" do
    config =
      runtime_config(%{
        "AUTH_CODE_LIMITS" =>
          ~s([{"action": "check", "by": "network", "limit": 500, "window": "hour"}])
      })

    assert config[:auth_code_limits][:overrides] == [{:check, :network, 500, :hour}]
  end

  test "a release reads its trusted proxies from TRUSTED_PROXIES" do
    config = runtime_config(%{"TRUSTED_PROXIES" => "127.0.0.1, 198.51.100.0/24"})

    assert config[MicaWeb.Plug.RemoteIp][:trusted_proxies] == ["127.0.0.1", "198.51.100.0/24"]
  end

  test "a release doesn't start with an invalid TRUSTED_PROXIES" do
    assert_raise ArgumentError, fn ->
      runtime_config(%{"TRUSTED_PROXIES" => "proxy.example.com"})
    end
  end

  test "a release doesn't start with a TRUSTED_PROXIES that lists no proxies" do
    assert_raise ArgumentError, fn -> runtime_config(%{"TRUSTED_PROXIES" => " , "}) end
  end

  test "a release doesn't start with an AUTH_CODE_LIMITS limit of 0" do
    assert_raise RuntimeError, fn ->
      runtime_config(%{
        "AUTH_CODE_LIMITS" =>
          ~s([{"action": "check", "by": "network", "limit": 0, "window": "hour"}])
      })
    end
  end
end
