use Mix.Config

# Do not print debug messages in production
config :logger, level: :info

config :core, CoreWeb.Endpoint, cache_static_manifest: "priv/static/cache_manifest.json"

config :core, SurfConext,
  site: "https://connect.test.surfconext.nl",
  client_id: System.get_env("SURFCONEXT_CLIENT_ID")

config :logger_json, :backend, metadata: :all

config :logger,
  backends: [LoggerJSON]
