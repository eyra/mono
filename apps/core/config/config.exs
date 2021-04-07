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

config :core, SignInWithApple,
  client_id: System.get_env("SIGN_IN_WITH_APPLE_CLIENT_ID"),
  team_id: System.get_env("SIGN_IN_WITH_APPLE_TEAM_ID"),
  private_key_id: System.get_env("SIGN_IN_WITH_APPLE_PRIVATE_KEY_ID"),
  redirect_uri: "https://localhost/apple/auth"

config :core, GoogleSignIn,
  client_id: "1027619588178-ckkft8qhcj2jev6bsonbuqghe6pn6isf.apps.googleusercontent.com",
  client_secret: "C-x02CCKC29o4OttKzhi0hE8",
  redirect_uri: "http://localhost:4000/google-sign-in/auth"

config :core, Core.ImageCatalog.Unsplash,
  access_key: "",
  app_name: "Core"

config :core, :children, [
  Core.Repo,
  CoreWeb.Telemetry,
  {Phoenix.PubSub, name: Core.PubSub}
]

import_config "#{Mix.env()}.exs"
