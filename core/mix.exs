defmodule Core.MixProject do
  use Mix.Project

  def project do
    [
      app: :core,
      version: "0.1.0",
      source_url: "https://github.com/eyra/mono",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() != :test,
      aliases: aliases(),
      deps: deps(),
      # The main page in the docs
      docs: [
        main: "readme",
        logo: "priv/static/images/icons/next.svg",
        extras: [
          "../SELFHOSTING.md",
          "../README.md",
          "../guides/development_setup.md",
          "../guides/authorization.md"
        ]
      ],
      gettext: [
        write_reference_comments: false
      ],
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        plt_add_apps: [:mix],
        flags: [
          # :unmatched_returns,
          :error_handling,
          # :race_conditions,
          :no_opaque
        ]
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Core.Application, []},
      extra_applications: [:logger, :runtime_tools, :csv, :ssl]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test),
    do: ["bundles", "apps", "systems", "frameworks", "lib", "test", "test/support"]

  defp elixirc_paths(:dev),
    do: ["bundles", "apps", "systems", "frameworks", "lib"]

  defp elixirc_paths(_), do: ["bundles", "apps", "systems", "frameworks", "lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      # Workaround for conflicting versions in ex_aws & ex_phone_number
      {:sweet_xml, "~> 0.7", override: true},
      # Deps
      {:appsignal_phoenix, "~> 2.6"},
      {:assent, "~> 0.2.3"},
      # Fork supports Phoenix 1.7
      {:bamboo_phoenix, git: "https://github.com/populimited/bamboo_phoenix.git"},
      {:bamboo_ses, "~> 0.4.5"},
      {:bamboo, "2.3.0"},
      {:bcrypt_elixir, "~> 2.0"},
      {:cldr_utils, "~> 2.28", override: true},
      {:csv, "~> 2.4"},
      {:currency_formatter, "~> 0.8"},
      {:ecto_commons, "~> 0.3.6"},
      {:ecto_sql, "~> 3.10"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:ex_aws_s3, "~> 2.5"},
      {:faker, "~> 0.17"},
      # Fork fixes a bug in the original package
      {:floki, git: "https://github.com/eyra/floki.git", override: true},
      {:gettext, "~> 0.19"},
      {:httpoison, "~> 2.2.1"},
      {:jason, "~> 1.4"},
      {:kadabra, "~> 0.6.0"},
      {:libcluster, "~> 3.3"},
      {:logger_json, "~> 4.3"},
      {:mime, "~> 2.0"},
      {:nimble_parsec, "~> 1.4"},
      {:nimble_options, "~> 1.0.0"},
      {:oban, "~> 2.18.3"},
      {:packmatic, "~> 1.2.0"},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_html, "~> 3.3.1"},
      {:phoenix_inline_svg, "~> 1.4"},
      {:phoenix_live_view, "~> 1.0.0"},
      {:phoenix_view, "~> 2.0"},
      {:phoenix, "1.7.17"},
      {:plug_cowboy, "~> 2.5"},
      {:postgrex, ">= 0.15.13"},
      {:remote_ip, "~> 1.1"},
      {:slugify, "~> 1.3"},
      {:statistics, "~> 0.6.2"},
      {:tailwind, "~> 0.2.0", runtime: Mix.env() == :dev},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:timex, "~> 3.7"},
      {:typed_struct, "~> 0.2.1"},
      {:tzdata, "~>  1.1.2"},
      # i18n
      {:ex_cldr, "~> 2.37"},
      {:ex_cldr_numbers, "~> 2.31"},
      {:ex_cldr_dates_times, "~> 2.10"},
      {:ex_cldr_plugs, "~> 1.2"},
      # Optional, but recommended for SSL validation with :httpc adapter
      {:certifi, "~> 2.8"},
      # Optional, but recommended for SSL validation with :httpc adapter
      {:ssl_verify_fun, "~> 1.1"},
      # Dev and test deps
      {:file_system, "~> 1.0.1", only: [:dev, :test]},
      {:bypass, "~> 2.1", only: :test},
      {:mox, "~> 1.0", only: :test},
      {:promox, "~> 0.1.0", only: :test},
      {:mock, "~> 0.3.0", only: :test},
      {:progress_bar, "~> 2.0.1", only: [:dev, :test]},
      {:phoenix_live_reload, "~> 1.5", only: :dev},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.26", only: [:dev, :test], runtime: false},
      {:table_rex, "~> 3.0.0"},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:browser, "~> 0.5.4"}
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
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.install", "assets.build"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"],
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "ecto.reset.link": [
        "ecto.drop",
        "ecto.create",
        "ecto.migrate",
        "run bundles/link/seeds.exs"
      ],
      i18n: [
        "gettext.extract --merge priv/gettext"
      ],
      makedocs: ["deps.get", "docs -o doc/output"],
      prettier: "cmd ./assets/node_modules/.bin/prettier --color --check ./assets/js",
      clean: ["cmd rm -rf deps", "cmd rm -rf _build", "cmd rm -rf priv/cldr"],
      "prettier.fix": "cmd ./assets/node_modules/.bin/prettier --color -w ./assets/js",
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.install": "cmd cd ./assets && npm install",
      "assets.build": ["tailwind default", "esbuild default"],
      "assets.deploy": ["tailwind default --minify", "esbuild default --minify", "phx.digest"],
      run: "phx.server"
    ]
  end
end
