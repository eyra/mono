# Tests of the env-name parity check. Run from core/:
#   elixir scripts/env_names_test.exs

Code.require_file("env_names.ex", __DIR__)
ExUnit.start()

defmodule EnvNamesTest do
  use ExUnit.Case, async: true

  @unit """
  [Service]
  ExecStart=/home/next/current/bin/core start
  Environment="APP_NAME={{app_name}}"
  Environment="DATABASE_URL={{db_url}}"
  {% if release_cookie is defined %}
  Environment="DIST_HOSTS={% for node in cluster_nodes %}{{node}}{% endfor %}"
  {% endif %}
  Environment="DB_NAME={{db_name}}"
  """

  @toml """
  app = 'eyra-next-staging'

  [build.args]
    FORCE_SSL = 'false'

  [env]
    # comment
    APP_NAME = 'Next [staging]'
    ECTO_IPV6 = 'true'

  [http_service]
    internal_port = 8000
  """

  @runtime """
  import Config

  if config_env() == :prod do
    env = System.get_env()
    config :core, name: System.fetch_env!("APP_NAME")
    config :core, Core.Repo, url: RuntimeConfig.fetch!(env, "DATABASE_URL")
    config :core, :dist_hosts, env["DIST_HOSTS"]
    config :core, :ipv6, System.get_env("ECTO_IPV6") == "true"
    raise "AWS_S3_BUCKET (\#{bucket}) must be private"
  end
  """

  describe "sources" do
    test "unit_names/1 reads the Environment= names, also inside template blocks" do
      assert EnvNames.unit_names(@unit) ==
               MapSet.new(~w(APP_NAME DATABASE_URL DIST_HOSTS DB_NAME))
    end

    test "conditional_unit_names/1 reads the names inside {% if %} blocks" do
      assert EnvNames.conditional_unit_names(@unit) == MapSet.new(["DIST_HOSTS"])
    end

    test "fly_env_names/1 reads only the [env] table" do
      assert EnvNames.fly_env_names(@toml) == MapSet.new(~w(APP_NAME ECTO_IPV6))
    end

    test "secret_names/1 reads the names of `fly secrets list --json`" do
      json =
        ~s([{"Name":"DATABASE_URL","Digest":"abc","CreatedAt":"2026-01-01"},{"Name":"MAILGUN_API_KEY"}])

      assert EnvNames.secret_names(json) == MapSet.new(~w(DATABASE_URL MAILGUN_API_KEY))
    end

    test "deploy_env_names/2 reads --env names of the workflow that deploys the toml" do
      staging =
        "flyctl deploy --remote-only -c fly.staging.toml \\\n  --env APPSIGNAL_REVISION=${{ env.REV }}"

      dev = "flyctl deploy -c fly.dev.toml --env OTHER=1"

      assert EnvNames.deploy_env_names([staging, dev], "fly.staging.toml") ==
               MapSet.new(["APPSIGNAL_REVISION"])
    end

    test "literal_names/1 marks fetch_env! and fetch!(env, …) names as required" do
      assert EnvNames.literal_names(@runtime) == %{
               "APP_NAME" => :required,
               "DATABASE_URL" => :required,
               "DIST_HOSTS" => :optional,
               "ECTO_IPV6" => :optional
             }
    end

    test "env_reads/1 reads System.get_env and fetch_env names" do
      source = ~S"""
      defmodule M do
        def a, do: System.get_env("USERCHECK_API_KEY")
        def b, do: System.fetch_env!("PAYMENT_PROVIDER")
        def c(name), do: System.get_env(name)
      end
      """

      assert EnvNames.env_reads(source) == %{
               "USERCHECK_API_KEY" => :optional,
               "PAYMENT_PROVIDER" => :required
             }
    end
  end

  describe "compare/4" do
    @reads %{
      "APP_NAME" => :required,
      "DATABASE_URL" => :required,
      "DIST_HOSTS" => :optional,
      "ECTO_IPV6" => :optional
    }

    defp compare(prod, staging, accepted) do
      EnvNames.compare(
        %{prod: MapSet.new(prod), staging: MapSet.new(staging)},
        @reads,
        MapSet.new(["FORCE_SSL"]),
        accepted
      )
    end

    test "passes when every difference is accepted" do
      report =
        compare(
          ~w(APP_NAME DATABASE_URL DIST_HOSTS DB_NAME),
          ~w(APP_NAME DATABASE_URL ECTO_IPV6),
          %{
            "DIST_HOSTS" => "cluster",
            "ECTO_IPV6" => "Fly",
            "DB_NAME" => "old name"
          }
        )

      assert report.differences.read_prod_only == MapSet.new(["DIST_HOSTS"])
      assert report.differences.read_staging_only == MapSet.new(["ECTO_IPV6"])
      assert report.differences.unread_prod == MapSet.new(["DB_NAME"])
      refute EnvNames.failed?(report)
    end

    test "fails on a required name one side does not set" do
      report = compare(~w(APP_NAME), ~w(APP_NAME DATABASE_URL), %{})

      assert report.required_missing.prod == MapSet.new(["DATABASE_URL"])
      assert EnvNames.failed?(report)
    end

    test "fails on a new difference and reports accepted entries that are gone" do
      report =
        compare(~w(APP_NAME DATABASE_URL), ~w(APP_NAME DATABASE_URL ECTO_IPV6), %{
          "DB_NAME" => "old"
        })

      assert report.unaccepted == MapSet.new(["ECTO_IPV6"])
      assert report.stale_accepted == MapSet.new(["DB_NAME"])
      assert EnvNames.failed?(report)
      assert EnvNames.format(report, "app") =~ "staging only:    ECTO_IPV6 (new)"
    end
  end

  test "the real runtime config reads the names it requires" do
    reads = EnvNames.read_names()

    for name <- ~w(APP_NAME APP_DOMAIN SECRET_KEY_BASE DATABASE_URL UPLOAD_PATH) do
      assert reads[name] == :required, "#{name} should be required"
    end

    assert reads["ENABLED_OBAN_PLUGINS"] == :optional
    assert reads["RELEASE_COOKIE"] == :optional
  end
end
