defmodule BankingProxy.MixProject do
  use Mix.Project

  def project do
    [
      app: :banking_proxy,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript(),
      docs: [
        main: "readme",
        logo: "../core/priv/static/images/icons/next.svg",
        extras: [
          "README.md"
        ]
      ]
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
    [main_module: Bunq.SetupCLI, name: "banking_setup", app: :hackney]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "== 2.2.3"},
      {:jason, "== 1.4.4"},
      {:ranch, "== 2.1.0"},
      # Dev and test deps
      {:mox, "== 1.2.0", only: :test},
      {:credo, "== 1.7.12", only: [:dev, :test], runtime: false},
      # {:exsync, "~> 0.2", only: :dev},
      {:dialyxir, "== 1.4.6", only: [:dev, :test], runtime: false},
      {:ex_doc, "== 0.38.4", only: [:dev, :test], runtime: false}
    ]
  end
end
