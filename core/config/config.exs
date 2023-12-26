# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :tailwind,
  version: "3.3.6",
  default: [
    args: ~w(
    --config=tailwind.config.js
    --input=css/app.css
    --output=../priv/static/assets/app.css
  ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :plug, :statuses, %{
  403 => "Access Denied",
  404 => "Page not found"
}

config :core,
  image_catalog: Core.ImageCatalog.Unsplash,
  banking_backend: Systems.Banking.Dummy

config :gettext, default_locale: "nl"

config :core, CoreWeb.Gettext, locales: ~w(en nl)

config :phoenix_inline_svg,
  dir: "./assets/static/images",
  default_collection: "icons"

config :core, Oban,
  repo: Core.Repo,
  queues: [default: 5, email_dispatchers: 1, email_delivery: 1, storage_delivery: 1],
  plugins: [
    {Oban.Plugins.Cron,
     crontab: [
       {"*/5 * * * *", Systems.Campaign.ExpirationWorker}
     ]}
  ]

config :core, :rate,
  prune_interval: 60 * 60 * 1000,
  quotas: [
    [service: :azure_blob, limit: 1000, unit: :call, window: :minute, scope: :local],
    [service: :azure_blob, limit: 10_000_000, unit: :byte, window: :day, scope: :local],
    [service: :azure_blob, limit: 1_000_000_000, unit: :byte, window: :day, scope: :global]
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

config :core, :s3, bucket: "port"

config :core, CoreWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "QbAmUdYcDMMQ2e7wVp6PSXI8QdUjfDEGR0FTwjwkUIYS4lW1ledjE9Dkhr3pE4Qn",
  server: true,
  force_ssl: [],
  render_errors: [
    formats: [html: CoreWeb.ErrorHTML, json: CoreWeb.ErrorHTML],
    layout: {CoreWeb.Layouts, :error}
  ],
  pubsub_server: Core.PubSub,
  live_view: [signing_salt: "U46ENwad8CDswjwuXgNZVpJjUlBjbmL9"],
  http: [port: 4000]

config :core, :ssl,
  client: :native,
  directory_url: {:internal, port: 4002},
  db_folder: Path.join("tmp", "site_encrypt_db"),
  domains: ["localhost"],
  emails: ["admin@localhost"]

config :core, :ssl_proxied, {:ok, "true"} == System.fetch_env("SSL_PROXIED")

config :web_push_encryption, :vapid_details,
  subject: "mailto:administrator@example.com",
  public_key: "use `mix web_push.gen.keypair`",
  private_key: ""

config :core, :version, System.get_env("VERSION", "dev")

config :core, :assignment, external_panels: ~w(liss ioresearch generic)

config :core, :storage, services: ~w(azure aws yoda)

config :core, BankingClient,
  host: 'localhost',
  port: 5555,
  cacertfile: "../banking_proxy/certs/ca_certificate.pem",
  certfile: "../banking_proxy/certs/client_certificate.pem",
  keyfile: "../banking_proxy/certs/client_key.pem"

config :sentry,
  included_environments: ~w(prod test),
  environment_name: Mix.env(),
  tags: %{app_version: System.get_env("VERSION", "dev")}

module =
  case Code.ensure_compiled(Bundle) do
    {:module, module} ->
      module

    _ ->
      [{module, _binary}] = Code.compile_file(".bundle.ex")
      module
  end

bundle = apply(module, :name, [])

config :core, :bundle, bundle

unless is_nil(bundle) do
  import_config "../bundles/#{bundle}/config/config.exs"
end

import_config "#{config_env()}.exs"
