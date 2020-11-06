use Mix.Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :link, Link.Repo,
  username: "postgres",
  password: "postgres",
  database: "link_test",
  hostname: "testdb",
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

# Registration of google oauth provider
config :link, :pow_assent,
  providers: [
    google: [
      client_id: "921548238010-bgv2ts6b3ih0q5d837nq4uh8rnrc3r6p.apps.googleusercontent.com",
      client_secret: "SAEest9ls0F_WOsyL0w5ShLv",
      strategy: Assent.Strategy.Google
    ]
  ]
