use Mix.Config

# Configure your database
config :core, Core.Repo,
  username: "postgres",
  password: "postgres",
  database: "link_dev",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :core, CoreWeb.Endpoint,
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/core_web/(live|views)/.*(ex)$",
      ~r"lib/core_web/templates/.*(eex)$",
      ~r"bundles/*/(live|views)/.*(ex)$",
      ~r"bundles/*/templates/.*(eex)$"
    ]
  ],
  watchers: [
    node: [
      "node_modules/webpack/bin/webpack.js",
      "--mode",
      "development",
      "--watch-stdin",
      cd: Path.expand("../assets", __DIR__)
    ]
  ]

config :exsync,
  addition_dirs: ["../../frameworks"]

# Load developer machine specific config. This can be used to setup secrets and
# such to connect with 3rd party services.
try do
  import_config "dev.local.exs"
rescue
  File.Error ->
    IO.puts(:stderr, "Local development config not found. 3rd party services might not work.")
end
