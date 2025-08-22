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
      # Fix for build warningns
      {:sweet_xml, "~> 0.7.4",
       github: "kbrw/sweet_xml", ref: "24bfac864f23c4b8864a010683e7c9549e99fe52", override: true},
      # Deps
      {:appsignal_phoenix, "== 2.6.0"},
      {:assent, "== 0.2.12"},
      # Fork supports Phoenix 1.7
      {:bamboo_phoenix,
       github: "populimited/bamboo_phoenix", ref: "d3cf4888cefd9ae9c5f5c2a386ed542b98e921b6"},
      {:bamboo_ses, "== 0.4.5"},
      {:bamboo, "== 2.3.1"},
      {:bcrypt_elixir, "== 3.2.0"},
      {:cldr_utils, "== 2.28.3", override: true},
      {:csv, "== 2.5.0"},
      {:ecto_commons, "== 0.3.6"},
      {:ecto_sql, "== 3.12.1"},
      {:esbuild, "== 0.8.2", runtime: Mix.env() == :dev},
      {:ex_aws_s3, "== 2.5.8"},
      # Unreleased commit fixes build warnings in the original repo
      {:faker, github: "elixirs/faker", ref: "1f42d2bf89f66214270804196b8863c860237518"},
      # Fork fixes a bug in the original repo
      {:floki, github: "eyra/floki", override: true},
      {:gettext, "== 0.26.2"},
      {:httpoison, "== 2.2.1"},
      {:image, "== 0.59.0"},
      {:jason, "== 1.4.4"},
      {:kadabra, "== 0.6.1"},
      {:libcluster, "== 3.4.1"},
      {:logger_json, "== 6.2.1"},
      {:live_nest, "~> 0.1.0",
       github: "eyra/live_nest", ref: "ba4aadc1e98b5c4829537caf8d8b109540a230fc"},
      {:mime, "== 2.0.7"},
      {:nimble_parsec, "== 1.4.0"},
      {:nimble_options, "== 1.0.2"},
      {:oban, "== 2.18.3"},
      # Fork fixes a dependency warning in the original repo
      {:packmatic, "~> 1.2.0",
       github: "ftes/packmatic", ref: "2774fb9cc545b4c3c096a1c0acb8e073efa43e39"},
      {:phoenix_ecto, "== 4.6.5"},
      {:phoenix_html, "== 3.3.4"},
      {:phoenix_inline_svg, "== 1.4.0"},
      {:phoenix_live_view, "== 1.0.10"},
      {:phoenix_view, "== 2.0.4"},
      {:phoenix, "== 1.7.21"},
      {:plug_cowboy, "== 2.7.4"},
      {:postgrex, "== 0.19.3"},
      {:remote_ip, "== 1.2.0"},
      {:slugify, "== 1.3.1"},
      {:sqids, "== 0.2.1"},
      {:statistics, "== 0.6.3"},
      {:tailwind, "== 0.2.4", runtime: Mix.env() == :dev},
      {:telemetry_metrics, "== 0.6.2"},
      {:telemetry_poller, "== 1.1.0"},
      {:timex, "~> 3.7",
       github: "copia-wealth-studios/timex", ref: "cc649c7a586f1266b17d57aff3c6eb1a56116ca2"},
      {:typed_struct, "== 0.2.1"},
      {:tzdata, "== 1.1.2"},
      # i18n
      {:ex_cldr, "== 2.40.2"},
      {:ex_cldr_numbers, "== 2.33.4"},
      {:ex_cldr_dates_times, "== 2.20.3"},
      {:ex_cldr_plugs, "== 1.3.3"},
      # Override Bypass dependency that is locked on Ranch 1.7.*
      {:ranch, "== 1.8.1", override: true},
      # Optional, but recommended for SSL validation with :httpc adapter
      {:certifi, "== 2.13.0"},
      # Optional, but recommended for SSL validation with :httpc adapter
      {:ssl_verify_fun, "== 1.1.7"},
      # Dev and test deps
      {:ex_machina, "== 2.8.0", only: :test},
      {:file_system, "== 1.0.1", only: [:dev, :test]},
      {:bypass, "~> 2.1",
       github: "PSPDFKit-labs/bypass",
       ref: "0a47472667340ed7d3b1250751408c44c6f9a7d7",
       only: :test},
      {:mox, "== 1.2.0", only: :test},
      {:promox, "== 0.1.4", only: :test},
      {:mock, "== 0.3.9", only: :test},
      {:progress_bar, "== 2.0.2", only: [:dev, :test]},
      {:phoenix_live_reload, "== 1.5.3", only: :dev},
      {:credo, "== 1.7.12", only: [:dev, :test], runtime: false},
      {:ex_doc, "== 0.38.3", only: [:dev, :test], runtime: false},
      {:table_rex, "== 3.0.0"},
      {:dialyxir, "== 1.4.5", only: [:dev, :test], runtime: false},
      {:browser, "== 0.5.5"}
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
