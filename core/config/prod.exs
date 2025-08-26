import Config

# Do not print debug messages in production
config :logger, level: :info

config :logger, :default_handler, formatter: {LoggerJSON.Formatters.Basic, metadata: :all}

config :core, CoreWeb.Endpoint, cache_static_manifest: "priv/static/cache_manifest.json"

config :core, SurfConext,
  site: "https://connect.test.surfconext.nl",
  client_id: System.get_env("SURFCONEXT_CLIENT_ID")

config :core, CoreWeb.Endpoint,
  force_ssl: [rewrite_on: [:x_forwarded_host, :x_forwarded_port, :x_forwarded_proto]]
