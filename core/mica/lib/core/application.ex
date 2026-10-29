defmodule Core.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Systems.Rate

  def start(_type, _args) do
    Appsignal.Logger.Handler.add("core")

    Core.AppSignal.TelemetryHandler.attach()

    Core.RuntimeConfig.log_choices()

    Core.FeatureFlags.warn_undeclared()

    Systems.Storage.BuiltIn.Backend.check_upload_path!()

    opts = [strategy: :one_for_one, name: Core.Supervisor]
    Supervisor.start_link(children(), opts)
  end

  def config_change(_changed, _new, _removed) do
    :ok
  end

  @doc false
  # Public for `mix nova.snapshot`.
  def children do
    topologies = [
      example: [
        strategy: Cluster.Strategy.Epmd,
        config: [hosts: dist_hosts()]
      ]
    ]

    [
      {Cluster.Supervisor, [topologies, [name: MyApp.ClusterSupervisor]]},
      Core.Repo,
      CoreWeb.Telemetry,
      {Phoenix.PubSub, name: Core.PubSub}
    ] ++
      Core.SaaS.children() ++
      [
        {Oban, oban_config(Core.Env.fetch!(Oban), Core.Env.get(:oban_plugins, []))},
        CoreWeb.Endpoint,
        {Rate.Server, rate_config(Core.Env.fetch!(:rate))}
      ]
  end

  @doc false
  # `config :core, Oban` with Mica's and the systems' queues, and the plugins and
  # crons `config :core, :oban_plugins` enables. Public for `mix nova.snapshot`.
  def oban_config(config, oban_plugins) do
    config
    |> Core.ObanConfig.config(Core.SaaS.oban_queues())
    |> Core.ObanConfig.put_plugins(Core.SaaS.oban_crons(), oban_plugins)
  end

  @doc false
  # `config :core, :rate`, with the systems' quotas unless it sets `quotas:` itself
  # (tests do). Public for `mix nova.snapshot`.
  def rate_config(config), do: Keyword.put_new_lazy(config, :quotas, &Core.SaaS.rate_quotas/0)

  defp dist_hosts do
    Core.Env.get(:dist_hosts, [])
  end
end
