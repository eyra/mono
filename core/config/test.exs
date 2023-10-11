import Config

# Print only errors during test
config :logger, level: :warn

# Setup for MinIO
config :ex_aws, :s3,
  scheme: "http://",
  host: "localhost",
  port: 9000

config :ex_aws,
  access_key_id: ["my_access_key"],
  secret_access_key: ["a_super_secret"]

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :core, Core.Repo,
  username: System.get_env("POSTGRES_USER", "postgres"),
  password: System.get_env("POSTGRES_PASS", "postgres"),
  database: "core_test",
  hostname: System.get_env("POSTGRES_HOST", "localhost"),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10,
  queue_target: 5000

# Reduce password hashing impact on test duration
config :bcrypt_elixir,
  log_rounds: 4

config :core, CoreWeb.Endpoint,
  http: [port: 4002],
  force_ssl: false,
  server: false

config :core, :features,
  sign_in_with_apple: true,
  member_google_sign_in: true,
  password_sign_in: true,
  notification_mails: true,
  debug_expire_force: true

config :core, Oban, queues: false, plugins: false

config :core, Core.SurfConext, oidc_module: Core.SurfConext.FakeOIDC

# Tests always use the next bundle
config :core, :bundle, :next

config :core, :banking_backend, Systems.Banking.Dummy

config :core, :feldspar,
  backend: Systems.Feldspar.LocalFS,
  local_fs_root_path: "/tmp"
