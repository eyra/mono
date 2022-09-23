# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :surface, :components, [
  {Surface.Components.Form, propagate_context_to_slots: true},
  {Frameworks.Pixel.Form.Form, propagate_context_to_slots: true},
  {CoreWeb.UI.Navigation.TabbarArea, propagate_context_to_slots: true}
]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :core,
  start_pages: CoreWeb.StartPages,
  image_catalog: Core.ImageCatalog.Unsplash,
  menu_items: CoreWeb.Menu.Items,
  workspace_menu_builder: CoreWeb.Layouts.Workspace.MenuBuilder,
  website_menu_builder: CoreWeb.Layouts.Website.MenuBuilder,
  stripped_menu_builder: CoreWeb.Layouts.Stripped.MenuBuilder,
  banking_backend: Systems.Banking.Dummy

config :core, CoreWeb.Gettext, default_locale: "nl", locales: ~w(en nl)

config :phoenix_inline_svg,
  dir: "./assets/static/images",
  default_collection: "icons"

config :esbuild,
  catalogue: [
    args:
      ~w(../deps/surface_catalogue/assets/js/app.js --bundle --target=es2016 --minify --outdir=../priv/static/assets/catalogue),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :core, Oban,
  repo: Core.Repo,
  queues: [default: 5, email_dispatchers: 1, email_delivery: 1],
  plugins: [
    {Oban.Plugins.Cron,
     crontab: [
       {"*/5 * * * *", Systems.Campaign.ExpirationWorker}
     ]}
  ]

config :core, ecto_repos: [Core.Repo]

config :core, Systems.Email.Mailer,
  adapter: Bamboo.TestAdapter,
  default_from_email: "no-reply@example.com"

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

config :core, Systems.DataDonation.S3StorageBackend, bucket: "port"

config :core, CoreWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "QbAmUdYcDMMQ2e7wVp6PSXI8QdUjfDEGR0FTwjwkUIYS4lW1ledjE9Dkhr3pE4Qn",
  server: true,
  force_ssl: [],
  render_errors: [view: CoreWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Core.PubSub,
  live_view: [signing_salt: "U46ENwad8CDswjwuXgNZVpJjUlBjbmL9"],
  http: [port: 4000]

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

config :core, :version, System.get_env("VERSION", "dev")

config :core, BankingClient,
  host: 'localhost',
  port: 5555,
  cacertfile: "../banking_proxy/certs/ca_certificate.pem",
  certfile: "../banking_proxy/certs/client_certificate.pem",
  keyfile: "../banking_proxy/certs/client_key.pem"

import_config "#{config_env()}.exs"

unless config_env() == :test do
  default_bundle =
    case File.read(".bundle") do
      {:ok, bundle} -> String.trim(bundle)
      {:error, _} -> "next"
    end

  bundle = System.get_env("BUNDLE", default_bundle) |> String.to_atom()

  config :core, :bundle, bundle

  unless is_nil(bundle) do
    import_config "../bundles/#{bundle}/config/config.exs"
  end
end
