defmodule Next.Config.RuntimeSnapshotTest do
  # Replaces the process environment while each fixture is evaluated.
  use ExUnit.Case, async: false

  alias Mica.RuntimeConfig
  alias Mix.Tasks.Config.Snapshot

  for fixture <- Snapshot.fixtures() do
    @fixture fixture
    test "runtime config for #{fixture.name} matches its snapshot" do
      assert Snapshot.render(@fixture) == File.read!(@fixture.snapshot), """
      The runtime config for #{@fixture.name} changed. Review the change, then run
      `BUNDLE=next mix config.snapshot --update` and commit the snapshot diff.
      """
    end
  end

  test "refuses donations in the public bucket" do
    %{env_file: env_file} = Enum.find(Snapshot.fixtures(), &(&1.name == "dev"))

    env =
      env_file
      |> RuntimeConfig.Snapshot.read_env_file()
      |> Map.put("AWS_S3_BUCKET", "eyra-next-dev-storage")

    assert_raise RuntimeError, ~r/AWS_S3_BUCKET .* must be a private bucket/, fn ->
      RuntimeConfig.Snapshot.evaluate("config/runtime.exs", env, :prod)
    end
  end

  test "refuses a local storage path inside the statically served upload path" do
    %{env_file: env_file} = Enum.find(Snapshot.fixtures(), &(&1.name == "prod-migrate"))

    env =
      env_file
      |> RuntimeConfig.Snapshot.read_env_file()
      |> Map.put("STORAGE_PATH", "/home/next/uploads/storage")

    assert_raise RuntimeError, ~r/STORAGE_PATH .* must not be inside UPLOAD_PATH/, fn ->
      RuntimeConfig.Snapshot.evaluate("config/runtime.exs", env, :prod)
    end

    assert_raise RuntimeError, ~r/STORAGE_PATH .* must not be inside UPLOAD_PATH/, fn ->
      RuntimeConfig.Snapshot.evaluate(
        "config/runtime.exs",
        %{env | "UPLOAD_PATH" => "/", "STORAGE_PATH" => "/home/next/storage"},
        :prod
      )
    end
  end

  test "every Oban plugin name enabled at once gives a valid Oban config with one Cron plugin" do
    %{env_file: env_file} =
      Enum.find(Snapshot.fixtures(), &(&1.name == "prod-all-oban-plugins"))

    env = RuntimeConfig.Snapshot.read_env_file(env_file)
    config = RuntimeConfig.Snapshot.evaluate("config/runtime.exs", env, :prod)
    oban_plugins = config[:mica][:oban_plugins]
    oban = Mica.Application.oban_config([repo: Mica.Repo], oban_plugins)
    plugins = Keyword.fetch!(oban, :plugins)

    # Oban starts each plugin under the child id {:plugin, module}.
    modules = Enum.map(plugins, &elem(&1, 0))
    assert modules == [Oban.Plugins.Pruner, Oban.Plugins.Lifeline, Oban.Plugins.Cron]

    assert [{Oban.Plugins.Cron, crontab: crontab}] =
             Enum.filter(plugins, &match?({Oban.Plugins.Cron, _}, &1))

    assert length(crontab) == 8
    assert Mica.ObanConfig.unknown_plugins(Mica.SaaS.oban_crons(), oban_plugins) == []
    assert :ok = Oban.Config.validate(oban)
  end

  # Without BUNDLE the test env has no SaaS, so no Next config: the snapshots would
  # lose Next's auth methods, and --update would write them that way.
  test "mix config.snapshot refuses a build without Next's config" do
    assert :ok = Snapshot.check_saas!(Next.SaaS)

    for saas <- [nil, MicaSaas.SaaS] do
      assert_raise Mix.Error, ~r/run BUNDLE=next mix config.snapshot/, fn ->
        Snapshot.check_saas!(saas)
      end
    end
  end
end
