use Mix.Config

# Configure your database
config :core, Core.Repo,
  username: "postgres",
  password: "postgres",
  database: "link_dev",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# Load developer machine specific config. This can be used to setup secrets and
# such to connect with 3rd party services.
try do
  import_config "dev.local.exs"
rescue
  File.Error ->
    IO.puts(:stderr, "Local development config not found. 3rd party services might not work.")
end
