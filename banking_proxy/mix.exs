defmodule BankingProxy.MixProject do
  use Mix.Project

  def project do
    [
      app: :banking_proxy,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {BankingProxy.App, []},
      extra_applications: [:logger]
    ]
  end

  def escript do
    [main_module: Bunq.SetupCLI, name: "banking_setup"]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 1.8"},
      {:jason, "~> 1.2"},
      {:ranch, "~> 2.1"},
      {:mox, "~> 1.0", only: :test}
    ]
  end
end
