use Mix.Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :link, Link.Repo,
  username: System.get_env("POSTGRES_USER", "link"),
  password: System.get_env("POSTGRES_PASS", ""),
  database: "link_test",
  hostname: System.get_env("POSTGRES_HOST", "localhost"),
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :link, LinkWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Reduce password hashing impact on test duration
config :pow, Pow.Ecto.Schema.Password, iterations: 1
