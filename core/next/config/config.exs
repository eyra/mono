import Config

config :mica, saas: Next.SaaS

config :mica, :account,
  auth_methods: %{
    surfconext: %{provider: true, satellite: true},
    centerdata: %{provider: true, satellite: true},
    google: %{provider: true, satellite: true, mx_provider: "google"},
    email: %{provider: false, satellite: true}
  }

config :mica, :pixel, pool_assets: [:panl, :panl_wide, :panl_dark, :panl_wide_dark]

# The endpoint (`use MicaWeb.Endpoint`). runtime.exs sets its port and, on a
# deployment, its URL and secret.
config :mica, NextWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "QbAmUdYcDMMQ2e7wVp6PSXI8QdUjfDEGR0FTwjwkUIYS4lW1ledjE9Dkhr3pE4Qn",
  server: true,
  force_ssl: false,
  render_errors: [
    formats: [html: MicaWeb.ErrorHTML, json: MicaWeb.ErrorJSON],
    layout: [html: {MicaWeb.Layouts, :error}]
  ],
  pubsub_server: Mica.PubSub,
  live_view: [signing_salt: "U46ENwad8CDswjwuXgNZVpJjUlBjbmL9"],
  http: [
    port: 4000,
    protocol_options: [
      idle_timeout: :infinity
    ]
  ],
  # Maximum HTTP body size for uploads (Plug.Parsers)
  http_body_max_size: 210_000_000

case config_env() do
  :dev ->
    config :mica, NextWeb.Endpoint,
      reloadable_compilers: [:elixir],
      force_ssl: false,
      debug_errors: true,
      code_reloader: true,
      check_origin: false,
      live_reload: [
        patterns: [
          ~r"priv/static/(?!uploads)/.*(js|css|png|jpeg|jpg|gif|svg)$",
          ~r"priv/gettext/.*(po)$",
          ~r"lib/mica_web/(live|views|components)/.*(ex|sface|js)$",
          ~r"lib/mica_web/templates/*/.*(eex)$",
          ~r"systems/*/.*(ex)$",
          ~r"systems/*/templates/.*(eex)$",
          ~r"frameworks/*/.*(ex)$",
          ~r"frameworks/*/templates/.*(eex)$",
          ~r"(next|mica_saas)/lib/.*(ex)$",
          ~r"(mica|next)/storybook/.*(exs)$"
        ]
      ],
      watchers: [
        esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]},
        tailwind: {Tailwind, :install_and_run, [:default, ~w(--watch)]}
      ]

  :prod ->
    config :mica, NextWeb.Endpoint, cache_static_manifest: "priv/static/cache_manifest.json"

    # SSL is terminated at the proxy (nginx/Fly). force_ssl provides defense-in-depth.
    # Set FORCE_SSL=false at build time to disable (e.g., for Fly.io where health checks use HTTP)
    if System.get_env("FORCE_SSL") != "false" do
      config :mica, NextWeb.Endpoint,
        force_ssl: [rewrite_on: [:x_forwarded_host, :x_forwarded_port, :x_forwarded_proto]]
    end

  :test ->
    config :mica, NextWeb.Endpoint, force_ssl: false, server: true
end
