defmodule Core.MixProject do
  use Mix.Project

  def project do
    [
      app: :core,
      version: "0.1.0",
      source_url: "https://github.com/eyra/mono",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() != :test,
      aliases: aliases(),
      deps: deps(),
      listeners: [Phoenix.CodeReloader],
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
        plt_add_apps: [:mix, :ex_unit],
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
      # Deps
      {:appsignal_phoenix, "== 2.7.0"},
      {:assent, "== 0.3.1"},
      # Fork supports Phoenix 1.8
      {:bamboo_phoenix,
       github: "eyra/bamboo_phoenix", ref: "59d3961228cb8bd315403cfbf48415aae19f25f1"},
      {:bamboo_ses, github: "eyra/bamboo_ses", ref: "04627cf1264291bbe2512420acd07f2f972d5585"},
      {:bamboo, "== 2.5.0"},
      {:bcrypt_elixir, "== 3.3.2"},
      {:cldr_utils, "== 2.28.3", override: true},
      {:csv, "== 3.2.2"},
      {:ecto_sql, "== 3.13.2"},
      {:esbuild, "== 0.10.0", runtime: Mix.env() == :dev},
      {:ex_aws_s3, "== 2.5.8"},
      # Unreleased commit fixes build warnings in the original repo
      {:faker, "== 0.19.0-alpha.1"},
      {:gen_smtp, "== 1.3.0"},
      {:gettext, "== 0.26.2"},
      {:hackney, "== 1.25.0"},
      {:httpoison, "== 2.2.3"},
      {:image, "== 0.62.0"},
      {:jason, "== 1.4.4"},
      {:kadabra, "== 0.6.1"},
      {:libcluster, "== 3.5.0"},
      {:logger_json, "== 7.0.4"},
      {:live_nest, github: "eyra/live_nest", ref: "ccc85f40883576517f870d7a9a4ed2f47044e230"},
      {:mime, "== 2.0.7"},
      {:nimble_parsec, "== 1.4.2"},
      {:nimble_options, "== 1.1.1"},
      {:oban, "== 2.20.1"},
      # Fork supports elixir 1.18.4
      {:packmatic, github: "eyra/packmatic", ref: "c7bd7b8a26d124e5b107a2a0f82e4f114d027849"},
      {:phoenix_ecto, "== 4.6.5"},
      {:phoenix_html, "== 4.2.1"},
      {:phoenix_html_helpers, "== 1.0.1"},
      {:phoenix_inline_svg, "== 1.4.0"},

      # Temporary: Using commit with fix for "no component for CID" errors
      # Bug: https://github.com/phoenixframework/phoenix_live_view/issues/3983
      # Fix: https://github.com/phoenixframework/phoenix_live_view/pull/3981
      # TODO: Switch back to hex version once released (likely 1.2.0)
      {:phoenix_live_view,
       github: "mellelieuwes/phoenix_live_view", ref: "1.1.11", override: true},
      {:phoenix_view, "== 2.0.4"},
      {:phoenix, "== 1.8.1"},
      {:plug_cowboy, "== 2.7.4"},
      {:postgrex, "== 0.21.1"},
      {:remote_ip, "== 1.2.0"},
      {:slugify, "== 1.3.1"},
      {:sqids, "== 0.2.1"},
      {:statistics, "== 0.6.3"},
      {:tailwind, "== 0.3.1", runtime: Mix.env() == :dev},
      {:telemetry_metrics, "== 1.1.0"},
      {:telemetry_poller, "== 1.3.0"},
      {:timex, "== 3.7.13"},
      {:typed_struct, "== 0.3.0"},
      {:tzdata, "== 1.1.3"},
      # i18n
      {:ex_cldr, "== 2.43.1"},
      {:ex_cldr_numbers, "== 2.35.1"},
      {:ex_cldr_dates_times, "== 2.23.0"},
      {:ex_cldr_plugs, "== 1.3.3"},
      # Optional, but recommended for SSL validation with :httpc adapter
      {:certifi, "== 2.15.0"},
      # Optional, but recommended for SSL validation with :httpc adapter
      {:ssl_verify_fun, "== 1.1.7"},
      # Dev and test deps
      {:ex_machina, "== 2.8.0", only: :test},
      {:file_system, "== 1.1.0", only: [:dev, :test]},
      {:bypass, "== 2.1.0", only: :test},
      {:lazy_html, "== 0.1.7", only: :test},
      {:mox, "== 1.2.0", only: :test},
      {:promox, "== 0.1.4", only: :test},
      {:mock, "== 0.3.9", only: :test},
      {:phoenix_live_reload, "== 1.6.1", only: :dev},
      {:credo, "== 1.7.12", only: [:dev, :test], runtime: false},
      {:ex_doc, "== 0.38.3", only: [:dev, :test], runtime: false},
      {:table_rex, "== 4.1.0"},
      {:dialyxir, "== 1.4.6", only: [:dev, :test], runtime: false},
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
      setup: [
        "deps.get",
        "ecto.setup",
        "assets.setup",
        "assets.install",
        "assets.build"
      ],
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
      "assets.deploy": [
        "tailwind default --minify",
        "esbuild default --minify",
        "phx.digest"
      ],
      run: "phx.server"
    ]
  end
end
