defmodule Core.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Systems.Banking
  alias Systems.Rate

  def start(_type, _args) do
    :logger.add_handler(:sentry_handler, Sentry.LoggerHandler, %{})

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
      {Oban, oban_config()},
      {Banking.Supervisor, [{:euro, "account-number"}]},
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
    Application.fetch_env!(:core, Oban)
  end

  defp rate_config do
    Application.fetch_env!(:core, :rate)
  end

  defp dist_hosts do
    Application.get_env(:core, :dist_hosts, [])
  end
end
