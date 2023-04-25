defmodule Core.MixProject do
  use Mix.Project

  def project do
    [
      app: :core,
      version: "0.1.0",
      source_url: "https://github.com/eyra/mono",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix] ++ Mix.compilers() ++ [:surface],
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      # The main page in the docs
      docs: [
        main: "readme",
        logo: "assets/static/images/desktop.svg",
        extras: [
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
      extra_applications: [:logger, :runtime_tools, :csv, :wx, :observer]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test),
    do: ["bundles", "apps", "systems", "frameworks", "lib", "test", "test/support"]

  defp elixirc_paths(:dev),
    do: ["bundles", "apps", "systems", "frameworks", "lib"] ++ catalogues()

  defp elixirc_paths(_), do: ["bundles", "apps", "systems", "frameworks", "lib"]

  def catalogues do
    [
      "priv/catalogue",
      "deps/surface/priv/catalogue"
    ]
  end

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      # Workaround for conflicting versions in ex_aws & ex_phone_number
      {:sweet_xml, "~> 0.7", override: true},
      # Deps
      {:assent, "~> 0.1.23"},
      {:bcrypt_elixir, "~> 2.0"},
      {:ex_aws_s3, "~> 2.0"},
      {:phoenix, "~> 1.6.12"},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_live_view, "~> 0.17.6"},
      {:phoenix_html, "~> 3.2"},
      {:phoenix_inline_svg, "~> 1.4"},
      {:surface, "~> 0.8.0"},
      {:surface_catalogue, "~> 0.5.1"},
      {:floki, ">= 0.27.0"},
      {:ecto_sql, "~> 3.7"},
      {:ecto_commons, "~> 0.3.3"},
      {:postgrex, ">= 0.15.13"},
      {:gettext, "~> 0.19"},
      {:jason, "~> 1.3"},
      {:plug_cowboy, "~> 2.5"},
      {:faker, "~> 0.17"},
      {:timex, "~> 3.7"},
      {:bamboo, "~> 2.2"},
      {:bamboo_phoenix, "~> 1.0.0"},
      {:bamboo_ses, "~> 0.3.0"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:currency_formatter, "~> 0.8"},
      {:web_push_encryption, "~> 0.3.1"},
      {:remote_ip, "~> 1.1"},
      {:pigeon, "~> 1.6.1"},
      {:kadabra, "~> 0.6.0"},
      {:oban, "~> 2.10"},
      {:nimble_parsec, "~> 1.2"},
      {:typed_struct, "~> 0.2.1"},
      {:logger_json, "~> 4.3"},
      {:statistics, "~> 0.6.2"},
      {:csv, "~> 2.4"},
      # i18n
      {:ex_cldr, "~> 2.25"},
      {:ex_cldr_numbers, "~> 2.23"},
      {:ex_cldr_dates_times, "~> 2.10"},
      {:ex_cldr_plugs, "~> 1.2"},
      # Optional, but recommended for SSL validation with :httpc adapter
      {:certifi, "~> 2.8"},
      # Optional, but recommended for SSL validation with :httpc adapter
      {:ssl_verify_fun, "~> 1.1"},
      # Dev and test deps
      {:file_system, "~> 0.2", only: [:dev, :test]},
      {:bypass, "~> 2.1", only: :test},
      {:mox, "~> 1.0", only: :test},
      {:progress_bar, "~> 2.0.1", only: [:dev, :test]},
      {:phoenix_live_reload, "~> 1.3", only: :dev},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.26", only: [:dev, :test], runtime: false},
      {:table_rex, "~> 3.0.0"},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:browser, "~> 0.4.4"}
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
      setup: ["deps.get", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
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
      "prettier.fix": "cmd ./assetsnode_modules/.bin/prettier --color -w ./assets/js"
    ]
  end
end
