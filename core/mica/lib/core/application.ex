defmodule Core.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Systems.Rate

  def start(_type, _args) do
    Appsignal.Logger.Handler.add("core")

    Core.AppSignal.TelemetryHandler.attach()

    topologies = [
      example: [
        strategy: Cluster.Strategy.Epmd,
        config: [hosts: dist_hosts()]
      ]
    ]

    children = [
      {Cluster.Supervisor, [topologies, [name: MyApp.ClusterSupervisor]]},
      Core.Repo,
      CoreWeb.Telemetry,
      {Phoenix.PubSub, name: Core.PubSub},
      {Registry, keys: :unique, name: Systems.Paper.RISProcessorRegistry},
      {Oban, oban_config()},
      CoreWeb.Endpoint,
      {Rate.Server, rate_config()}
    ]

    opts = [strategy: :one_for_one, name: Core.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(_changed, _new, _removed) do
    :ok
  end

  defp oban_config do
    Core.Env.fetch!(Oban)
  end

  defp rate_config do
    Core.Env.fetch!(:rate)
  end

  defp dist_hosts do
    Core.Env.get(:dist_hosts, [])
  end
end
