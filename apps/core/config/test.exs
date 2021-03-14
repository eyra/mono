use Mix.Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :core, Core.Repo,
  username: System.get_env("POSTGRES_USER", "postgres"),
  password: System.get_env("POSTGRES_PASS", "postgres"),
  database: "link_test",
  hostname: System.get_env("POSTGRES_HOST", "localhost"),
  pool: Ecto.Adapters.SQL.Sandbox

# Configures the endpoint
config :core, CoreWeb.Support.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "QbAmUdYcDMMQ2e7wVp6PSXI8QdUjfDEGR0FTwjwkUIYS4lW1ledjE9Dkhr3pE4Qn",
  render_errors: [view: CoreWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Core.PubSub,
  live_view: [signing_salt: "U46ENwad8CDswjwuXgNZVpJjUlBjbmL9"]

config :core, :children, [
  Core.Repo,
  CoreWeb.Telemetry,
  {Phoenix.PubSub, name: Core.PubSub},
  CoreWeb.Support.Endpoint
]

# Print only warnings and errors during test
config :logger, level: :warn

# Reduce password hashing impact on test duration
config :bcrypt_elixir,
  log_rounds: 4
