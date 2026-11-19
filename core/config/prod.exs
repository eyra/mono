import Config

# Do not print debug messages in production
config :logger, level: :info

config :logger, :default_handler, formatter: {LoggerJSON.Formatters.Basic, metadata: :all}

config :mica, Surfconext,
  site: "https://connect.test.surfconext.nl",
  client_id: System.get_env("SURFCONEXT_CLIENT_ID")
