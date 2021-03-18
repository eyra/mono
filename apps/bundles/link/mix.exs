defmodule Link.MixProject do
  use Mix.Project

  def project do
    [
      app: :link,
      version: "0.1.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      # The main page in the docs
      docs: [
        main: "readme",
        logo: "assets/static/images/eyra-logo.svg",
        extras: [
          "README.md",
          "guides/development_setup.md",
          "guides/authorization.md",
          "guides/green_light.md"
        ]
      ],
      dialyzer: [
        plt_add_apps: [:mix],
        plt_add_deps: :transitive
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Link.Application, []},
      extra_applications: [:logger, :runtime_tools, :inets]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]

  defp elixirc_paths(_) do
    project_path = __ENV__.file |> String.split("/") |> Enum.drop(-3) |> Enum.join("/")
    frameworks_path = project_path <> "/lib/frameworks"

    [frameworks_path, "lib"]
  end

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:core, path: "../../core"},
      # Dev and test deps
      {:progress_bar, "~> 2.0.1", only: [:dev, :test]},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:credo, "~> 1.5.0-rc.2", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
      {:table_rex, "~> 3.0.0"},
      {:phx_gen_auth, "~> 0.6", only: [:dev], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:exsync, "~> 0.2", only: :dev}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "build_js"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      ci: ["setup", "test", "credo"],
      i18n: [
        "gettext.extract --merge priv/gettext"
      ],
      makedocs: ["deps.get", "docs -o doc/output"]
    ]
  end
end
