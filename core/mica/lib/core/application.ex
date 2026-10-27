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
      {Phoenix.PubSub, name: Core.PubSub},
      {Registry, keys: :unique, name: Systems.Paper.RISProcessorRegistry},
      {Oban, oban_config(Core.Env.fetch!(Oban))},
      CoreWeb.Endpoint,
      {Rate.Server, rate_config(Core.Env.fetch!(:rate))}
    ]
  end

  @doc false
  # The Oban config started from `config :core, Oban`. Public for `mix nova.snapshot`.
  def oban_config(config), do: config

  @doc false
  # The rate server config started from `config :core, :rate`. Public for `mix nova.snapshot`.
  def rate_config(config), do: config

  defp dist_hosts do
    Core.Env.get(:dist_hosts, [])
  end
end
