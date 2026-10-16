defmodule Core.RuntimeConfigTest do
  use ExUnit.Case, async: true

  alias Core.RuntimeConfig

  @url "ecto://user:pass@db.example.org/app"

  describe "fetch!/2" do
    test "returns a set value" do
      assert RuntimeConfig.fetch!(%{"NAME" => "value"}, "NAME") == "value"
    end

    test "raises naming the missing variable" do
      assert_raise System.EnvError, ~r/NAME/, fn -> RuntimeConfig.fetch!(%{}, "NAME") end
    end
  end

  describe "list/1" do
    test "splits, trims and drops empty items" do
      assert RuntimeConfig.list(" a,b , ,c, ") == ["a", "b", "c"]
    end

    test "is empty for an unset or empty value" do
      assert RuntimeConfig.list(nil) == []
      assert RuntimeConfig.list("") == []
    end
  end

  describe "repo/1" do
    test "requires DATABASE_URL" do
      assert_raise System.EnvError, ~r/DATABASE_URL/, fn -> RuntimeConfig.repo(%{}) end
    end

    test "connects without TLS when DB_CA_PATH is not set" do
      assert RuntimeConfig.repo(%{"DATABASE_URL" => @url}) == [url: @url]
    end

    test "verifies the peer with SNI from the URL host when DB_CA_PATH is set" do
      env = %{"DATABASE_URL" => @url, "DB_CA_PATH" => "/ca.pem"}

      assert RuntimeConfig.repo(env) == [
               url: @url,
               ssl: [
                 cacertfile: "/ca.pem",
                 verify: :verify_peer,
                 server_name_indication: ~c"db.example.org"
               ]
             ]
    end

    test "skips verification only for DB_TLS_VERIFY=verify_none" do
      env = %{"DATABASE_URL" => @url, "DB_CA_PATH" => "/ca.pem"}

      assert RuntimeConfig.repo(Map.put(env, "DB_TLS_VERIFY", "verify_none"))[:ssl][:verify] ==
               :verify_none

      assert RuntimeConfig.repo(Map.put(env, "DB_TLS_VERIFY", "other"))[:ssl][:verify] ==
               :verify_peer
    end

    test "connects over IPv6 when ECTO_IPV6 is true or 1" do
      for value <- ~w(true 1) do
        env = %{"DATABASE_URL" => @url, "ECTO_IPV6" => value}
        assert RuntimeConfig.repo(env)[:socket_options] == [:inet6]
      end

      refute Keyword.has_key?(
               RuntimeConfig.repo(%{"DATABASE_URL" => @url, "ECTO_IPV6" => "false"}),
               :socket_options
             )
    end
  end

  describe "s3/1" do
    test "takes keys and region from the environment" do
      env = %{"AWS_ACCESS_KEY_ID" => "id", "AWS_SECRET_ACCESS_KEY" => "secret"}

      assert RuntimeConfig.s3(env) == [
               access_key_id: "id",
               secret_access_key: "secret",
               region: nil
             ]
    end

    test "points S3 at AWS_ENDPOINT_URL_S3, with region auto by default" do
      env = %{
        "AWS_ENDPOINT_URL_S3" => "https://s3.example.org",
        "AWS_ACCESS_KEY_ID" => "id",
        "AWS_SECRET_ACCESS_KEY" => "secret"
      }

      assert RuntimeConfig.s3(env) == [
               access_key_id: "id",
               secret_access_key: "secret",
               region: "auto",
               s3: [scheme: "https://", host: "s3.example.org", port: 443]
             ]
    end

    test "requires the keys with a custom endpoint" do
      assert_raise System.EnvError, ~r/AWS_ACCESS_KEY_ID/, fn ->
        RuntimeConfig.s3(%{"AWS_ENDPOINT_URL_S3" => "https://s3.example.org"})
      end
    end
  end

  describe "mailer/2" do
    @opts [
      name: "App",
      domain: "app.example.org",
      mail_domain: "mail.example.org",
      mailgun_base_uri: "https://mailgun.example.org"
    ]

    test "uses Mailgun when MAILGUN_API_KEY is set" do
      assert RuntimeConfig.mailer(%{"MAILGUN_API_KEY" => "key"}, @opts) == [
               adapter: Bamboo.MailgunAdapter,
               base_uri: "https://mailgun.example.org",
               api_key: "key",
               domain: "mail.example.org",
               default_from_email: "App <no-reply@mail.example.org>",
               hackney_opts: [recv_timeout: 60_000]
             ]
    end

    test "uses SES otherwise" do
      env = %{
        "AWS_REGION" => "eu-central-1",
        "AWS_ACCESS_KEY_ID" => "id",
        "AWS_SECRET_ACCESS_KEY" => "secret"
      }

      assert RuntimeConfig.mailer(env, @opts) == [
               adapter: Bamboo.SesAdapter,
               domain: "app.example.org",
               default_from_email: {"App", "no-reply@mail.example.org"}
             ]
    end

    test "requires the AWS region and keys for SES" do
      assert_raise System.EnvError, ~r/AWS_REGION/, fn -> RuntimeConfig.mailer(%{}, @opts) end
    end
  end

  describe "features/2" do
    test "enables the listed features" do
      env = %{"ENABLED_APP_FEATURES" => "debug, e2e"}
      assert RuntimeConfig.features(env, :staging) == [debug: true, e2e: true]
    end

    test "never enables :e2e on prod" do
      env = %{"ENABLED_APP_FEATURES" => "debug, e2e"}
      assert RuntimeConfig.features(env, :prod) == [debug: true]
    end

    test "keeps empty items, as the parser always did" do
      assert RuntimeConfig.features(%{}, :prod) == ["": true]
    end
  end

  describe "dist_hosts/1" do
    test "names the release node on each host" do
      env = %{"DIST_HOSTS" => "host-a, host-b"}
      assert RuntimeConfig.dist_hosts(env) == [:"core@host-a", :"core@host-b"]
    end

    test "is empty without DIST_HOSTS" do
      assert RuntimeConfig.dist_hosts(%{}) == []
    end
  end

  describe "oban_plugins/2" do
    @table [
      {"pruner", {:plugin, {Oban.Plugins.Pruner, max_age: 60}}},
      {"first_cron", {:cron, {"* * * * *", FirstWorker}}},
      {"lifeline", {:plugin, {Oban.Plugins.Lifeline, []}}},
      {"second_cron", {:cron, {"0 * * * *", SecondWorker, queue: :other}}}
    ]

    test "puts every enabled cron entry in one Cron plugin, in table order" do
      env = %{"ENABLED_OBAN_PLUGINS" => "second_cron, lifeline, first_cron, pruner"}

      assert RuntimeConfig.oban_plugins(env, @table) == {
               [
                 {Oban.Plugins.Pruner, max_age: 60},
                 {Oban.Plugins.Lifeline, []},
                 {Oban.Plugins.Cron,
                  crontab: [
                    {"* * * * *", FirstWorker},
                    {"0 * * * *", SecondWorker, queue: :other}
                  ]}
               ],
               []
             }
    end

    test "adds no Cron plugin when no cron name is enabled" do
      env = %{"ENABLED_OBAN_PLUGINS" => "pruner"}
      assert RuntimeConfig.oban_plugins(env, @table) == {[{Oban.Plugins.Pruner, max_age: 60}], []}
    end

    test "returns unknown names" do
      env = %{"ENABLED_OBAN_PLUGINS" => "pruner, typo, typo"}
      assert {_, ["typo"]} = RuntimeConfig.oban_plugins(env, @table)
    end

    test "enables nothing when unset" do
      assert RuntimeConfig.oban_plugins(%{}, @table) == {[], []}
    end
  end
end
