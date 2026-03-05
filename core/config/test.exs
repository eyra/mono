import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Reduce password hashing impact on test duration
config :bcrypt_elixir,
  log_rounds: 4

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

config :core, Core.SurfConext, oidc_module: Core.SurfConext.FakeOIDC

config :core, CoreWeb.Endpoint,
  http: [port: 4002],
  force_ssl: false,
  server: true

config :core, Oban, queues: false, plugins: false
config :core, :banking_backend, Systems.Banking.Dummy

# Tests always use the next bundle
config :core, :bundle, :next
config :core, :content, backend: Systems.Content.LocalFS

config :core, :features,
  sign_in_with_apple: true,
  member_google_sign_in: true,
  password_sign_in: true,
  notification_mails: true,
  debug_expire_force: true

config :core, :feldspar, backend: Systems.Feldspar.LocalFS

# Feldspar data donation file storage for tests
config :core, :feldspar_data_donation,
  path: "/tmp/data_donations_test",
  retention_hours: 336

# Paper system configuration for tests
config :core, :paper,
  # Use smaller file size limit for tests (10MB)
  ris_max_file_size: 10_485_760,
  # Use smaller chunk size for tests (1KB)
  ris_stream_chunk_size: 1_024

# Higher rate limit for concurrent upload tests
config :core, :rate,
  quotas: [
    [service: :feldspar_data_donation, limit: 100, unit: :call, window: :minute, scope: :local]
  ]

config :core,
  name: "Next [test]",
  base_url: "http://localhost:4000",
  upload_path: "/tmp"

# Selectical test configuration
config :core,
  selectical_base_url: "https://jkntvyihutapdkdsoleo.supabase.co",
  selectical_api_key:
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImprbnR2eWlodXRhcGRrZHNvbGVvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTU1ODk2NzksImV4cCI6MjAzMTE2NTY3OX0.zTsZmd3EdKFGof1gxI0LxD2aws2BGb2rboFybC_26Gk"

# Setup for MinIO
config :ex_aws, :s3,
  scheme: "http://",
  host: "localhost",
  port: 9000

config :ex_aws,
  access_key_id: ["my_access_key"],
  secret_access_key: ["a_super_secret"]

# Print only errors during test
config :logger, level: :error

# Wallaby configuration
config :wallaby,
  otp_app: :core,
  base_url: "http://localhost:4002",
  driver: Wallaby.Chrome,
  screenshot_dir: "tmp/wallaby_screenshots",
  screenshot_on_failure: true,
  chromedriver: [
    headless: System.get_env("WALLABY_HEADLESS", "true") == "true"
  ]

try do
  import_config "test.secret.exs"
rescue
  File.Error ->
    # Continuing without `test.secret.exs` file...
    nil
end
