defmodule Mica.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Systems.Rate

  def start(_type, _args) do
    Appsignal.Logger.Handler.add("core")

    Mica.AppSignal.TelemetryHandler.attach()

    Mica.RuntimeConfig.log_choices()

    Mica.FeatureFlags.warn_undeclared()

    Systems.Storage.BuiltIn.Backend.check_upload_path!()

    opts = [strategy: :one_for_one, name: Mica.Supervisor]
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
      Mica.Repo,
      MicaWeb.Telemetry,
      {Phoenix.PubSub, name: Mica.PubSub}
    ] ++
      Mica.SaaS.children() ++
      [
        {Oban, oban_config(Mica.Env.fetch!(Oban), Mica.Env.get(:oban_plugins, []))},
        MicaWeb.Endpoint,
        {Rate.Server, rate_config(Mica.Env.fetch!(:rate))}
      ]
  end

  @doc false
  # `config :mica, Oban` with Mica's and the systems' queues, and the plugins and
  # crons `config :mica, :oban_plugins` enables. Public for `mix nova.snapshot`.
  def oban_config(config, oban_plugins) do
    config
    |> Mica.ObanConfig.config(Mica.SaaS.oban_queues())
    |> Mica.ObanConfig.put_plugins(Mica.SaaS.oban_crons(), oban_plugins)
  end

  @doc false
  # `config :mica, :rate`, with the systems' quotas unless it sets `quotas:` itself
  # (tests do). Public for `mix nova.snapshot`.
  def rate_config(config), do: Keyword.put_new_lazy(config, :quotas, &Mica.SaaS.rate_quotas/0)

  defp dist_hosts do
    Mica.Env.get(:dist_hosts, [])
  end
end
