import Config

# Setup for MinIO
config :ex_aws, :s3,
  scheme: "http://",
  host: "localhost",
  port: 9000

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

config :logger, level: :info

# Configure your database
config :core, Core.Repo,
  username: "postgres",
  password: "postgres",
  database: "link_dev",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :core, CoreWeb.Endpoint,
  reloadable_compilers: [:elixir],
  force_ssl: false,
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  live_reload: [
    patterns: [
      ~r"priv/static/(?!uploads)/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/core_web/(live|views|components)/.*(ex|sface|js)$",
      ~r"lib/core_web/templates/*/.*(eex)$",
      ~r"bundles/*/.*(ex)$",
      ~r"bundles/*/templates/.*(eex)$"
    ]
  ],
  watchers: [
    node: [
      "node_modules/webpack/bin/webpack.js",
      "--mode",
      "development",
      "--watch-stdin",
      cd: Path.expand("../assets", __DIR__)
    ]
  ]

config :core,
  admins: [
    "*@eyra.co"
  ]

config :core, :rate,
  prune_interval: 5 * 1000,
  quotas: [
    [service: :azure_blob, limit: 1, unit: :call, window: :second, scope: :local],
    [service: :azure_blob, limit: 100, unit: :byte, window: :second, scope: :local]
  ]

config :core, Core.ImageCatalog.Unsplash,
  access_key: System.get_env("UNSPLASH_ACCESS_KEY"),
  app_name: System.get_env("UNSPLASH_APP_NAME")

config :core, image_catalog: Core.ImageCatalog.Unsplash

config :core, Systems.Email.Mailer,
  adapter: Bamboo.LocalAdapter,
  open_email_in_browser_url: "http://localhost:4000/sent_emails",
  default_from_email: "no-reply@example.com"

config :core, :apns_backend, Core.APNS.LoggingBackend

config :core,
       :static_path,
       File.cwd!()
       |> Path.join("tmp")
       |> Path.join("uploads")
       |> tap(&File.mkdir_p!/1)

config :core,
       :admins,
       ["e.vanderveen@eyra.co"]

config :core, :s3, bucket: "eylixir"

config :core,
       :data_donation_storage_backend,
       fake: Systems.DataDonation.FakeStorageBackend,
       s3: Systems.DataDonation.S3StorageBackend,
       azure: Systems.DataDonation.AzureStorageBackend,
       centerdata: Systems.DataDonation.CenterdataStorageBackend

#  For Minio (local S3)
config :ex_aws,
  access_key_id: "my_access_key",
  secret_access_key: "a_super_secret"

try do
  import_config "dev.secret.exs"
rescue
  File.Error ->
    # Continuing without `dev.secret.exs` file...
    nil
end
