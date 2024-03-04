import Config

upload_path =
  File.cwd!()
  |> Path.join("priv")
  |> Path.join("static")
  |> Path.join("uploads")
  |> tap(&File.mkdir_p!/1)

config :core,
  name: "Next [local]",
  base_url: "http://localhost:4000",
  upload_path: upload_path

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

config :logger, level: :debug

# Configure your database
config :core, Core.Repo,
  username: "postgres",
  password: "postgres",
  database: "next_dev",
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
      ~r"systems/*/.*(ex)$",
      ~r"systems/*/templates/.*(eex)$",
      ~r"frameworks/*/.*(ex)$",
      ~r"frameworks/*/templates/.*(eex)$",
      ~r"bundles/*/.*(ex)$",
      ~r"bundles/*/templates/.*(eex)$"
    ]
  ],
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:default, ~w(--watch)]}
  ]

config :core,
  admins: [
    "*@eyra.co"
  ]

config :core, Systems.Storage.BuiltIn, special: Systems.Storage.BuiltIn.LocalFS

config :core, :rate,
  prune_interval: 5 * 60 * 1000,
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
       :admins,
       ["e.vanderveen@eyra.co"]

# #  For Minio (local S3)
# config :ex_aws,
#   scheme: "http://",
#   host: "localhost",
#   port: 9000
#   access_key_id: "my_access_key",
#   secret_access_key: "a_super_secret"

config :core, :content, backend: Systems.Content.LocalFS

config :core, :feldspar, backend: Systems.Feldspar.LocalFS

try do
  import_config "dev.secret.exs"
rescue
  File.Error ->
    # Continuing without `dev.secret.exs` file...
    nil
end
