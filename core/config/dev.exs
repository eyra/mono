import Config

# Setup for MinIO
config :ex_aws, :s3,
  scheme: "http://",
  host: "localhost",
  port: 9000

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1
# Configure your database
config :core, Core.Repo,
  username: "postgres",
  password: "postgres",
  database: "link_dev",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :core, CoreWeb.Endpoint,
  reloadable_compilers: [:gettext, :elixir, :surface],
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
      ~r"bundles/*/templates/.*(eex)$",
      ~r"priv/catalogue/.*(ex)$"
    ]
  ],
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:catalogue, ~w(--sourcemap=inline --watch)]},
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

config :core, Core.ImageCatalog.Unsplash,
  access_key: System.get_env("UNSPLASH_ACCESS_KEY"),
  app_name: System.get_env("UNSPLASH_APP_NAME")

config :core, image_catalog: Core.ImageCatalog.Unsplash

config :core, Core.Mailer,
  adapter: Bamboo.LocalAdapter,
  default_from_email: "no-reply@example.com"

config :web_push_encryption, :vapid_details,
  subject: "mailto:administrator@example.com",
  public_key:
    "BLddMfMPHE67WZkYxELLBedpRNvJMj7xTbn8ZsObC_0c1-p-AsHl7ndhoty2YURTgCR0XMPm6Mf-74FnwH32fhw",
  private_key: "yWo9lKKkdbN1IGQH8aUlk3u_Shemyh8CmtDnJoNdhBk"

config :core, :apns_backend, backend: Core.APNS.LoggingBackend

config :core,
       :static_path,
       File.cwd!()
       |> Path.join("tmp")
       |> Path.join("uploads")
       |> tap(&File.mkdir_p!/1)

config :core,
       :admins,
       ["e.vanderveen@eyra.co"]

config :core, Systems.DataDonation.S3StorageBackend, bucket: "eylixir"

config :core,
       :data_donation_storage_backend,
       s3: Systems.DataDonation.S3StorageBackend,
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
