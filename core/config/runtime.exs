import Config

if config_env() == :prod do
  app_name = System.fetch_env!("APP_NAME")
  app_domain = System.fetch_env!("APP_DOMAIN")
  app_mail_domain = System.fetch_env!("APP_MAIL_DOMAIN")
  app_mail_noreply = "no-reply@#{app_mail_domain}"

  # Allow enabling of features from an environment variable
  config :core,
         :features,
         System.get_env("ENABLED_APP_FEATURES", "")
         |> String.split(~r"\s*,\s*")
         |> Enum.map(&String.to_existing_atom/1)
         |> Enum.map(&{&1, true})

  config :core,
         :admins,
         System.get_env("APP_ADMINS", "") |> String.split() |> Systems.Admin.Public.compile()

  config :core, :static_path, System.fetch_env!("STATIC_PATH")

  config :core, CoreWeb.Endpoint,
    cache_static_manifest: "priv/static/cache_manifest.json",
    server: true,
    secret_key_base: System.fetch_env!("SECRET_KEY_BASE"),
    url: [host: app_domain, scheme: "https", port: 443],
    http: [
      port: String.to_integer(System.get_env("HTTP_PORT", "8000"))
    ]

  # MAILGUN

  if mailgun_api_key = System.get_env("MAILGUN_API_KEY") do
    config :core, Systems.Email.Mailer,
      adapter: Bamboo.MailgunAdapter,
      base_uri: "https://api.eu.mailgun.net/v2",
      api_key: mailgun_api_key,
      domain: app_domain,
      default_from_email: "#{app_name} <#{app_mail_noreply}>",
      hackney_opts: [recv_timeout: :timer.minutes(1)]
  end

  # AWS

  if bucket = System.get_env("AWS_S3_BUCKET") do
    config :core, :s3, bucket: bucket
  end

  if aws_access_key_id = System.get_env("AWS_ACCESS_KEY_ID") do
    config :ex_aws, access_key_id: aws_access_key_id

    config :core, Systems.Email.Mailer,
      adapter: Bamboo.SesAdapter,
      domain: app_domain,
      default_from_email: {app_name, app_mail_noreply}
  end

  if secret_access_key = System.get_env("AWS_SECRET_ACCESS_KEY") do
    config :ex_aws, secret_access_key: secret_access_key
  end

  if aws_region = System.get_env("AWS_REGION") do
    config :ex_aws, region: aws_region
  end

  # AZURE BLOB

  if container = System.get_env("AZURE_BLOB_CONTAINER") do
    config :core, :azure_storage_backend, container: container
  end

  if storage_account_name = System.get_env("AZURE_BLOB_STORAGE_USER") do
    config :core, :azure_storage_backend, storage_account_name: storage_account_name
  end

  if sas_token = System.get_env("AZURE_SAS_TOKEN") do
    config :core, :azure_storage_backend, sas_token: sas_token
  end

  database_url = System.get_env("DB_URL")

  if database_url do
    config :core, Core.Repo, url: database_url
  else
    config :core, Core.Repo,
      username: System.get_env("DB_USER"),
      password: System.get_env("DB_PASS"),
      database: System.get_env("DB_NAME"),
      hostname: System.get_env("DB_HOST")
  end

  config :core, GoogleSignIn,
    redirect_uri: "https://#{app_domain}/google-sign-in/auth",
    client_id: System.get_env("GOOGLE_SIGN_IN_CLIENT_ID"),
    client_secret: System.get_env("GOOGLE_SIGN_IN_CLIENT_SECRET")

  config :core, Core.SurfConext,
    redirect_uri: "https://#{app_domain}/surfconext/auth",
    site: System.get_env("SURFCONEXT_SITE"),
    client_id: System.get_env("SURFCONEXT_CLIENT_ID"),
    client_secret: System.get_env("SURFCONEXT_CLIENT_SECRET")

  config :core, SignInWithApple,
    redirect_uri: "https://#{app_domain}/apple/auth",
    client_id: System.get_env("SIGN_IN_WITH_APPLE_CLIENT_ID"),
    team_id: System.get_env("SIGN_IN_WITH_APPLE_TEAM_ID"),
    private_key_id: System.get_env("SIGN_IN_WITH_APPLE_PRIVATE_KEY_ID"),
    private_key_path: System.get_env("SIGN_IN_WITH_APPLE_PRIVATE_KEY_PATH")

  config :core, Core.ImageCatalog.Unsplash,
    access_key: System.get_env("UNSPLASH_ACCESS_KEY"),
    app_name: System.get_env("UNSPLASH_APP_NAME")

  config :web_push_encryption, :vapid_details,
    subject: "mailto:admin@#{app_mail_domain}",
    public_key: System.get_env("WEB_PUSH_PUBLIC_KEY"),
    private_key: System.get_env("WEB_PUSH_PRIVATE_KEY")

  config :logger, level: System.get_env("LOG_LEVEL", "info") |> String.to_existing_atom()

  config :sentry,
    dsn: System.get_env("SENTRY_DSN"),
    environment_name: System.get_env("RELEASE_ENV") || "prod"

  config :core, :feldspar,
    backend: Systems.Feldspar.S3,
    bucket: System.get_env("FELDSPAR_S3_BUCKET"),
    prefix: System.get_env("FELDSPAR_S3_PREFIX", ""),
    # The public URL must point to the root's (bucket) publicly accessible URL.
    # It should have a policy that allows anonymous users to read all files.
    public_url: System.get_env("FELDSPAR_S3_PUBLIC_URL")
end
