import Config

if config_env() == :prod do
  host = System.fetch_env!("BUNDLE_DOMAIN")

  config :link, LinkWeb.Endpoint,
    cache_static_manifest: "priv/static/cache_manifest.json",
    server: true,
    secret_key_base: System.fetch_env!("SECRET_KEY_BASE"),
    url: [host: host, port: 443],
    http: [
      port: String.to_integer(System.get_env("HTTP_PORT", "80"))
    ],
    https: [port: String.to_integer(System.get_env("HTTPS_PORT", "443"))]

  config :core, Core.Repo,
    username: System.get_env("DB_USER"),
    password: System.get_env("DB_PASS"),
    database: System.get_env("DB_NAME"),
    hostname: System.get_env("DB_HOST")

  config :core, Core.Mailer, adapter: Bamboo.LocalAdapter

  config :core, GoogleSignIn,
    redirect_uri: "https://#{host}/google-sign-in/auth",
    client_id: System.get_env("GOOGLE_SIGN_IN_CLIENT_ID"),
    client_secret: System.get_env("GOOGLE_SIGN_IN_CLIENT_SECRET")

  config :core, Core.SurfConext,
    redirect_uri: "https://#{host}/surfconext/auth",
    site: System.get_env("SURFCONEXT_SITE"),
    client_id: System.get_env("SURFCONEXT_CLIENT_ID"),
    client_secret: System.get_env("SURFCONEXT_CLIENT_SECRET")

  config :core, SignInWithApple,
    redirect_uri: "https://#{host}/apple/auth",
    client_id: System.get_env("SIGN_IN_WITH_APPLE_CLIENT_ID"),
    team_id: System.get_env("SIGN_IN_WITH_APPLE_TEAM_ID"),
    private_key_id: System.get_env("SIGN_IN_WITH_APPLE_PRIVATE_KEY_ID"),
    private_key_path: System.get_env("SIGN_IN_WITH_APPLE_PRIVATE_KEY_PATH")

  config :core, Core.ImageCatalog.Unsplash,
    access_key: System.get_env("UNSPLASH_ACCESS_KEY"),
    app_name: System.get_env("UNSPLASH_APP_NAME")

  config :core, Core.Mailer,
    adapter: Bamboo.MailgunAdapter,
    api_key: System.get_env("MAILGUN_API_KEY"),
    domain: host,
    hackney_opts: [recv_timeout: :timer.minutes(1)]

  config :link, :ssl,
    domains: [host],
    emails: [System.get_env("LETS_ENCRYPT_EMAIL", "admin@#{host}")],
    directory_url: System.get_env("LETS_ENCRYPT_DIRECTORY_URL"),
    db_folder: System.get_env("LETS_ENCRYPT_DB")
end
