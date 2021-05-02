use Mix.Config

# Do not print debug messages in production
config :logger, level: :info

config :core, SurfConext,
  site: "https://connect.test.surfconext.nl",
  client_id: System.get_env("SURFCONEXT_CLIENT_ID")
