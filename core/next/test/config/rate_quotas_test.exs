defmodule Next.Config.RateQuotasTest do
  # Replaces the process environment while runtime.exs is evaluated.
  use ExUnit.Case, async: false

  alias Mica.RuntimeConfig
  alias Mix.Tasks.Config.Snapshot
  alias Systems.Rate

  # RATE_QUOTAS as the production inventory sets it.
  @rate_quotas ~s([
    {"service": "storage_export", "limit": 6, "unit": "call", "window": "minute", "scope": "local"},
    {"service": "signup", "limit": 5, "unit": "call", "window": "minute", "scope": "local"},
    {"service": "recruit", "limit": 5, "unit": "call", "window": "minute", "scope": "local"}
  ])

  setup_all do
    %{env_file: env_file} = Enum.find(Snapshot.fixtures(), &(&1.name == "prod"))

    env =
      env_file
      |> RuntimeConfig.Snapshot.read_env_file()
      |> Map.put("RATE_QUOTAS", @rate_quotas)

    config =
      Config.Reader.merge(
        Config.Reader.read!("config/config.exs", env: :prod, target: :host),
        RuntimeConfig.Snapshot.evaluate("config/runtime.exs", env, :prod)
      )

    {:ok, state} = config[:mica][:rate] |> Mica.Application.rate_config() |> Rate.Server.init()
    %{quotas: Enum.map(state.quotas, &{&1.service, &1.limit, &1.unit, &1.window, &1.scope})}
  end

  test "a release keeps the otp_request default that RATE_QUOTAS doesn't list", %{quotas: quotas} do
    assert {"otp_request", 3, :call, :minute, :local} in quotas
  end

  test "a release uses the RATE_QUOTAS quota of a service it lists", %{quotas: quotas} do
    assert Enum.filter(quotas, &(elem(&1, 0) == "storage_export")) == [
             {"storage_export", 6, :call, :minute, :local}
           ]
  end

  test "a release has no default quota for the Feldspar donate and log API", %{quotas: quotas} do
    assert Enum.filter(quotas, &(elem(&1, 0) in ["feldspar_data_donation", "feldspar_log"])) ==
             []
  end
end
