# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :mime, :types, %{
  "application/x-research-info-systems" => ["ris"]
}

# Deployment environment used by seed modules to decide which seeds to run.
# Possible values: :local, :dev, :test, :staging, :prod
# Defaults to :local for developer machines (mix dev, mix test).
# Releases override this in runtime.{aws,fly}.exs based on the DEPLOY_ENV env var,
# defaulting to :prod for safety.
config :core, :deploy_env, :local

# UserCheck email validation. Default to real HTTP client; dev/test override to mock.
config :core, Frameworks.UserCheck,
  client: Frameworks.UserCheck.HTTPClient,
  base_url: "https://api.usercheck.com",
  timeout: 2_000

# Use Jason for JSON parsing in Phoenix
config :phoenix,
  json_library: Jason,
  filter_parameters: ["password", "secret"]

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
  metadata: [
    :request_id,
    :request_path,
    :query_string,
    :user_agent,
    :method,
    :path,
    :duration_ms,
    :status
  ]

config :plug, :statuses, %{
  403 => "Access Denied",
  404 => "Page not found"
}

config :core, :signal,
  handlers: [
    "Core.APNS.SignalHandlers",
    "Core.Mailer.SignalHandlers",
    "Core.WebPush.SignalHandlers",
    "Systems.Account.Switch",
    "Systems.Admin.Switch",
    "Systems.Advert.Switch",
    "Systems.Alliance.Switch",
    "Systems.Assignment.Switch",
    "Systems.Consent.Switch",
    "Systems.Crew.Switch",
    "Systems.Feldspar.Switch",
    "Systems.Graphite.Switch",
    "Systems.Instruction.Switch",
    "Systems.Manual.Switch",
    "Systems.NextAction.Switch",
    "Systems.Observatory.Switch",
    "Systems.Pool.Switch",
    "Systems.Project.Switch",
    "Systems.Storage.Switch",
    "Systems.Student.Switch",
    "Systems.Workflow.Switch",
    "Systems.Zircon.Switch"
  ]

config :core, CoreWeb.FileUploader, max_file_size: 100_000_000

# Maximum HTTP body size for uploads (Plug.Parsers)
config :core, CoreWeb.Endpoint, http_body_max_size: 210_000_000

config :core,
  greenlight_auth_module: Core.Authorization,
  image_catalog: Core.ImageCatalog.Unsplash,
  banking_backend: Systems.Banking.Dummy,
  payment_provider: Systems.Payment.Provider.Local,
  payment_providers: %{
    "opp" => Systems.Payment.Provider.OPP
  },
  tool_directors: [:assignment]

config :core, Systems.Payment.Provider.OPP,
  base_url: "https://api-sandbox.onlinebetaalplatform.nl/v1"

config :gettext, default_locale: "en"

config :core, CoreWeb.Gettext, locales: ~w(en es de it nl ro lt)

config :phoenix_inline_svg,
  dir: "./assets/static/images",
  default_collection: "icons"

config :core, Oban,
  repo: Core.Repo,
  queues: false

config :packmatic, Packmatic.Source.URL,
  hackney: [
    pool: :default
  ]

config :core, :rate,
  prune_interval: 60 * 60 * 1000,
  quotas: [
    [service: :azure_blob, limit: 1000, unit: :call, window: :minute, scope: :local],
    [service: :azure_blob, limit: 10_000_000, unit: :byte, window: :day, scope: :local],
    [service: :azure_blob, limit: 1_000_000_000, unit: :byte, window: :day, scope: :global],
    [service: :storage_export, limit: 1, unit: :call, window: :minute, scope: :local],
    [service: :feldspar_data_donation, limit: 1, unit: :byte, window: :day, scope: :local],
    [service: :feldspar_log, limit: 60, unit: :call, window: :minute, scope: :local],
    [service: :signup, limit: 5, unit: :call, window: :minute, scope: :local]
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
  client_id: System.get_env("GOOGLE_SIGN_IN_CLIENT_ID"),
  client_secret: System.get_env("GOOGLE_SIGN_IN_CLIENT_SECRET"),
  redirect_uri: "http://localhost:4000/google-sign-in/auth"

config :core, Core.ImageCatalog.Unsplash,
  access_key: "",
  app_name: "Core"

config :core, :s3, bucket: "port"

config :core, CoreWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "QbAmUdYcDMMQ2e7wVp6PSXI8QdUjfDEGR0FTwjwkUIYS4lW1ledjE9Dkhr3pE4Qn",
  server: true,
  force_ssl: false,
  render_errors: [
    formats: [html: CoreWeb.ErrorHTML, json: CoreWeb.ErrorJSON],
    layout: [html: {CoreWeb.Layouts, :error}]
  ],
  pubsub_server: Core.PubSub,
  live_view: [signing_salt: "U46ENwad8CDswjwuXgNZVpJjUlBjbmL9"],
  http: [
    port: 4000,
    protocol_options: [
      idle_timeout: :infinity
    ]
  ]

config :core, :ssl,
  client: :native,
  directory_url: {:internal, port: 4002},
  db_folder: Path.join("tmp", "site_encrypt_db"),
  domains: ["localhost"],
  emails: ["admin@localhost"]

config :core, :ssl_proxied, {:ok, "true"} == System.fetch_env("SSL_PROXIED")

config :core, :version, System.get_env("VERSION", "dev")

config :core, :assignment, external_panels: ~w(liss ioresearch generic)

config :core, :storage,
  services: ~w(builtin yoda),
  job_scheduler: Systems.Storage.JobScheduler.Oban

# Default built-in storage backend (can be overridden in runtime.exs for production)
config :core, Systems.Storage.BuiltIn, special: Systems.Storage.BuiltIn.LocalFS

config :core, BankingClient,
  host: "localhost",
  port: 5555,
  cacertfile: "../banking_proxy/certs/ca_certificate.pem",
  certfile: "../banking_proxy/certs/client_certificate.pem",
  keyfile: "../banking_proxy/certs/client_key.pem"

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

config :core, :zircon,
  screening: [
    agent_module: Systems.Zircon.Screening.HumanAgent
  ]

# Paper system import configuration
config :core, :paper,
  import_batch_size: 100,
  import_batch_timeout: 30_000,
  # Maximum allowed RIS file size (default 150MB - supports ~100,000 paper references)
  ris_max_file_size: 157_286_400,
  # Chunk size for streaming RIS files (default 64KB)
  ris_stream_chunk_size: 65_536

# Temp file store for Storage system (stores data donations before delivery)
config :core, :temp_file_store, module: Systems.Feldspar.DataDonationFolder

import_config "#{config_env()}.exs"
