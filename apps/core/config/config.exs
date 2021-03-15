# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :core, CoreWeb.Gettext, default_locale: "nl", locales: ~w(en nl)

config :core, ecto_repos: [Core.Repo]
config :core, default_from_email: "test@example.org"

config :core, Core.SurfConext,
  client_id: "not-set",
  client_secret: "not-set",
  site: "https://connect.test.surfconext.nl",
  redirect_uri: "not-set"

config :core, :children, [
  Core.Repo,
  CoreWeb.Telemetry,
  {Phoenix.PubSub, name: Core.PubSub}
]

import_config "#{Mix.env()}.exs"
