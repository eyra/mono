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
      ~r"priv/static/(?!uploads)/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/core_web/(live|views)/.*(ex)$",
      ~r"lib/core_web/templates/.*(eex)$",
      ~r"bundles/*/.*(ex)$",
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

config :core, Core.ImageCatalog.Unsplash,
  access_key: System.get_env("UNSPLASH_ACCESS_KEY"),
  app_name: System.get_env("UNSPLASH_APP_NAME")

config :exsync,
  addition_dirs: ["../../frameworks"]
