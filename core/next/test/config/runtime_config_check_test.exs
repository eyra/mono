defmodule Next.Config.RuntimeConfigCheckTest do
  # Replaces the process environment while runtime.exs is evaluated.
  use ExUnit.Case, async: false

  alias Core.RuntimeConfig.Check
  alias Core.RuntimeConfig.Snapshot

  @password "db-password-must-not-show"

  setup do
    dir = Path.join(System.tmp_dir!(), "config_check_#{System.unique_integer([:positive])}")
    File.mkdir_p!(Path.join(dir, "uploads"))
    ca_path = Path.join(dir, "ca.pem")
    File.write!(ca_path, "")
    on_exit(fn -> File.rm_rf!(dir) end)

    %{dir: dir, ca_path: ca_path}
  end

  # The config a release gets: the build-time config (config.exs and prod.exs),
  # with runtime.exs evaluated for `fixture` and `overrides` merged on top.
  defp config(fixture, overrides) do
    env =
      "next/test/config/env/#{fixture}.env"
      |> Snapshot.read_env_file()
      |> Map.merge(%{
        "SECRET_KEY_BASE" => String.duplicate("s", 64),
        "DATABASE_URL" => "ecto://next:#{@password}@db.example.com/next"
      })
      |> Map.merge(overrides)
      |> Map.reject(fn {_, value} -> is_nil(value) end)

    build_time = [core: [{Oban, [repo: Core.Repo]}]]
    Config.Reader.merge(build_time, Snapshot.evaluate("config/runtime.exs", env, :prod))
  end

  defp prod(%{ca_path: ca_path}, overrides \\ %{}),
    do: config("prod", Map.merge(%{"DB_CA_PATH" => ca_path}, overrides))

  test "passes the production environment", context do
    assert {:ok, _warnings} = Check.check(prod(context))
  end

  test "passes the migrate environment, which stores donations locally", context do
    assert {:ok, _warnings} =
             Check.check(
               config("prod-migrate", %{
                 "DB_CA_PATH" => context.ca_path,
                 "UPLOAD_PATH" => Path.join(context.dir, "uploads")
               })
             )
  end

  test "refuses a short SECRET_KEY_BASE", context do
    assert {:error, ["SECRET_KEY_BASE: must be at least 64 bytes"], _} =
             Check.check(prod(context, %{"SECRET_KEY_BASE" => "short"}))
  end

  test "refuses an invalid DATABASE_URL without printing it", context do
    url = "ecto://next:#{@password}@db.example.com"

    assert {:error, [problem], _} = Check.check(prod(context, %{"DATABASE_URL" => url}))
    assert problem == "DATABASE_URL: not a valid database URL"
    refute problem =~ @password
  end

  test "refuses a DB_CA_PATH without a file", context do
    missing = Path.join(context.dir, "missing.pem")

    assert {:error, [problem], _} = Check.check(prod(context, %{"DB_CA_PATH" => missing}))
    assert problem =~ "DB_CA_PATH: no file at"
  end

  test "refuses an invalid rate quota", context do
    quotas = ~s([{"service":"export","limit":1,"unit":"lines","window":"minute","scope":"local"}])

    assert {:error, [problem], _} = Check.check(prod(context, %{"RATE_QUOTAS" => quotas}))
    assert problem =~ "RATE_QUOTAS:"
  end

  test "refuses an invalid cleanup schedule", context do
    assert {:error, [problem], _} =
             Check.check(
               prod(context, %{
                 "ENABLED_OBAN_PLUGINS" => "data_donation_cleanup",
                 "FELDSPAR_CLEANUP_SCHEDULE" => "every night"
               })
             )

    assert problem =~ "Oban (ENABLED_OBAN_PLUGINS, FELDSPAR_CLEANUP_SCHEDULE):"
  end

  test "refuses donations left in UPLOAD_PATH by an earlier version", context do
    upload_path = Path.join(context.dir, "uploads")
    File.mkdir_p!(Path.join(upload_path, "project_node=1"))

    assert {:error, [problem], _} =
             Check.check(
               config("prod-migrate", %{
                 "DB_CA_PATH" => context.ca_path,
                 "UPLOAD_PATH" => upload_path
               })
             )

    assert problem =~ "UPLOAD_PATH:"
    assert problem =~ "project_node=1"
  end

  test "warns about unknown Oban plugin names", context do
    assert {:ok, warnings} =
             Check.check(prod(context, %{"ENABLED_OBAN_PLUGINS" => "pruner, prunner"}))

    assert "ENABLED_OBAN_PLUGINS: unknown name(s) ignored: prunner" in warnings
  end
end
