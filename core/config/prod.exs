import Config

# Do not print debug messages in production
config :logger, level: :info

config :logger, :default_handler, formatter: {LoggerJSON.Formatters.Basic, metadata: :all}

config :core, CoreWeb.Endpoint, cache_static_manifest: "priv/static/cache_manifest.json"

config :core, SurfConext,
  site: "https://connect.test.surfconext.nl",
  client_id: System.get_env("SURFCONEXT_CLIENT_ID")

ssl_enabled =
  System.get_env("FORCE_SSL", "true")
  |> String.downcase()
  |> Kernel.in?(["true", "1"])

raw_rewrite = System.get_env("REWRITE_ON", "")

rewrite_on_list =
  case String.split(raw_rewrite, ",", trim: true) do
    [] -> [:x_forwarded_host, :x_forwarded_port, :x_forwarded_proto]
    list -> Enum.map(list, &String.to_atom/1)
  end

force_ssl_opts =
  if ssl_enabled do
    [rewrite_on: rewrite_on_list]
  else
    false
  end

config :core, CoreWeb.Endpoint, force_ssl: force_ssl_opts
