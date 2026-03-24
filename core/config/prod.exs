import Config

# Do not print debug messages in production
config :logger, level: :info

config :logger, :default_handler, formatter: {LoggerJSON.Formatters.Basic, metadata: :all}

config :core, CoreWeb.Endpoint, cache_static_manifest: "priv/static/cache_manifest.json"

config :core, SurfConext,
  site: "https://connect.test.surfconext.nl",
  client_id: System.get_env("SURFCONEXT_CLIENT_ID")

config :core, payment_provider: Systems.Payment.Provider.OPP

# SSL is terminated at the proxy (nginx/Fly). force_ssl provides defense-in-depth.
# Set FORCE_SSL=false at build time to disable (e.g., for Fly.io where health checks use HTTP)
if System.get_env("FORCE_SSL") != "false" do
  config :core, CoreWeb.Endpoint,
    force_ssl: [rewrite_on: [:x_forwarded_host, :x_forwarded_port, :x_forwarded_proto]]
end
