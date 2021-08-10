# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :core,
  image_catalog: Core.ImageCatalog.Unsplash,
  promotion_plugins: [data_donation: CoreWeb.DataDonation.PromotionPlugin],
  menu_items: CoreWeb.Menu.Items,
  workspace_menu_builder: CoreWeb.Layouts.Workspace.MenuBuilder,
  website_menu_builder: CoreWeb.Layouts.Website.MenuBuilder

config :core, CoreWeb.Gettext, default_locale: "nl", locales: ~w(en nl)

config :core, Oban,
  repo: Core.Repo,
  plugins: [],
  queues: [default: 5]

config :core, ecto_repos: [Core.Repo]

config :core, Core.Mailer, adapter: Bamboo.TestAdapter, default_from_email: "no-reply@example.com"

config :core, Core.SurfConext,
  client_id: "not-set",
  client_secret: "not-set",
  site: "https://connect.test.surfconext.nl",
  redirect_uri: "not-set",
  limit_schac_home_organization: nil

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

config :core, CoreWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "QbAmUdYcDMMQ2e7wVp6PSXI8QdUjfDEGR0FTwjwkUIYS4lW1ledjE9Dkhr3pE4Qn",
  server: true,
  force_ssl: [],
  render_errors: [view: CoreWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Core.PubSub,
  live_view: [signing_salt: "U46ENwad8CDswjwuXgNZVpJjUlBjbmL9"],
  http: [port: 4000],
  https: [port: 4001]

config :core, :ssl,
  client: :native,
  directory_url: {:internal, port: 4002},
  db_folder: Path.join("tmp", "site_encrypt_db"),
  domains: ["localhost"],
  emails: ["admin@localhost"]

config :web_push_encryption, :vapid_details,
  subject: "mailto:administrator@example.com",
  public_key: "use `mix web_push.gen.keypair`",
  private_key: ""

import_config "#{Mix.env()}.exs"

default_bundle =
  case File.read(".bundle") do
    {:ok, bundle} -> String.trim(bundle)
    {:error, _} -> "next"
  end

bundle = System.get_env("BUNDLE", default_bundle) |> String.to_atom()

config :core, :bundle, bundle

unless is_nil(bundle) do
  import_config "../bundles/#{bundle}/config.exs"
end
