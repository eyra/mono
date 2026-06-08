import Config

# Feature tests run a real HTTP server on a fixed port and share a database via
# Wallaby's shared-sandbox mode, so concurrent runs (e.g. multiple developer or
# agent sessions) collide on both resources. FEATURE_TEST_SESSION gives each
# session an isolated HTTP port and database. Unset (0) reproduces the default
# port (4002) and database (core_test), so normal single-session runs are
# unchanged.
feature_test_session =
  System.get_env("FEATURE_TEST_SESSION", "0")
  |> case do
    "" -> 0
    n -> String.to_integer(n)
  end

feature_test_port = 4002 + feature_test_session
feature_test_base_url = "http://localhost:#{feature_test_port}"

feature_test_db_suffix =
  if feature_test_session == 0, do: "", else: to_string(feature_test_session)

config :core,
  name: "Next [test]",
  base_url: feature_test_base_url,
  upload_path: "/tmp"

# Selectical test configuration
config :core,
  selectical_base_url: "https://jkntvyihutapdkdsoleo.supabase.co",
  selectical_api_key:
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImprbnR2eWlodXRhcGRrZHNvbGVvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTU1ODk2NzksImV4cCI6MjAzMTE2NTY3OX0.zTsZmd3EdKFGof1gxI0LxD2aws2BGb2rboFybC_26Gk",
  payment_provider: Systems.Payment.ProviderMock

config :core, Systems.Payment.Provider.OPP,
  notification_secret: "test_notification_secret",
  merchant_uid: "mer_platform_test"

# Compile in E2E support facilities (e.g. local payment simulator).
config :core, :enable_e2e_support, true

# Print only errors during test
config :logger, level: :error

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
  database: "core_test#{feature_test_db_suffix}",
  hostname: System.get_env("POSTGRES_HOST", "localhost"),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 33,
  queue_target: 5000

# Reduce password hashing impact on test duration
config :bcrypt_elixir,
  log_rounds: 4

# Paper system configuration for tests
config :core, :paper,
  # Use smaller file size limit for tests (10MB)
  ris_max_file_size: 10_485_760,
  # Use smaller chunk size for tests (1KB)
  ris_stream_chunk_size: 1_024

config :core, CoreWeb.Endpoint,
  http: [port: feature_test_port],
  force_ssl: false,
  server: true

# Wallaby configuration
config :wallaby,
  otp_app: :core,
  base_url: feature_test_base_url,
  driver: Wallaby.Chrome,
  screenshot_dir: "tmp/wallaby_screenshots",
  screenshot_on_failure: true,
  # Increase wait time for slow CI environments where JS takes longer to execute
  max_wait_time: String.to_integer(System.get_env("WALLABY_MAX_WAIT_TIME", "5000")),
  chromedriver: [
    headless: System.get_env("WALLABY_HEADLESS", "true") == "true"
  ]

config :core, :features,
  sign_in_with_apple: true,
  member_google_sign_in: true,
  password_sign_in: true,
  notification_mails: true,
  debug_expire_force: true,
  panl: true,
  panl_post_launch: true,
  e2e: true

config :core, Frameworks.UserCheck, client: Frameworks.UserCheck.MockClient

config :core, Oban, queues: false, plugins: false

config :core, Core.SurfConext, oidc_module: Core.SurfConext.FakeOIDC

# Tests always use the next bundle
config :core, :bundle, :next

config :core, :banking_backend, Systems.Banking.Dummy

config :core, :content, backend: Systems.Content.LocalFS

config :core, :feldspar, backend: Systems.Feldspar.LocalFS

# Feldspar data donation file storage for tests
config :core, :feldspar_data_donation,
  path: "/tmp/data_donations_test",
  retention_hours: 336

# Higher rate limit for concurrent upload tests
config :core, :rate,
  quotas: [
    [service: :feldspar_data_donation, limit: 100, unit: :call, window: :minute, scope: :local],
    [service: :feldspar_log, limit: 100, unit: :call, window: :minute, scope: :local],
    [service: :signup, limit: 100, unit: :call, window: :minute, scope: :local]
  ]

try do
  import_config "test.secret.exs"
rescue
  File.Error ->
    # Continuing without `test.secret.exs` file...
    nil
end
