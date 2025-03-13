import Config

if config_env() == :prod do
  app_name = System.fetch_env!("APP_NAME")
  app_domain = System.fetch_env!("APP_DOMAIN")
  app_mail_domain = System.fetch_env!("APP_MAIL_DOMAIN")
  app_mail_noreply = "no-reply@#{app_mail_domain}"
  upload_path = System.fetch_env!("STATIC_PATH")

  scheme = "https"
  base_url = "#{scheme}://#{app_domain}"

  config :core,
    name: app_name,
    base_url: base_url,
    upload_path: upload_path

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

  config :core, CoreWeb.Endpoint,
    cache_static_manifest: "priv/static/cache_manifest.json",
    server: true,
    secret_key_base: System.fetch_env!("SECRET_KEY_BASE"),
    url: [host: app_domain, scheme: scheme, port: 443],
    http: [
      port: String.to_integer(System.get_env("HTTP_PORT", "8000"))
    ]

  # PHOENIX LIVE UPLOAD

  config :core, CoreWeb.FileUploader,
    max_file_size: System.get_env("STORAGE_UPLOAD_MAX_SIZE", "100000000") |> String.to_integer()

  # RATE LIMITER

  config :core, :rate, quotas: System.get_env("RATE_QUOTAS", "[]") |> Jason.decode!()

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

  # EX AWS
  config :ex_aws,
    access_key_id: System.get_env("AWS_ACCESS_KEY_ID"),
    secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY"),
    region: System.get_env("AWS_REGION")

  # AWS SES
  config :core, Systems.Email.Mailer,
    adapter: Bamboo.SesAdapter,
    domain: app_domain,
    default_from_email: {app_name, app_mail_noreply}

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

  # DATABASE
  cacertfile = System.get_env("DB_CA_PATH")

  verify_mode =
    case System.get_env("DB_TLS_VERIFY") do
      "verify_peer" -> :verify_peer
      "verify_none" -> :verify_none
      _ -> :verify_peer
    end

  database_url = System.get_env("DB_URL")
  db_host = System.fetch_env!("DB_HOST")

  if database_url do
    config :core, Core.Repo,
      url: database_url,
      ssl: [
        cacertfile: cacertfile,
        verify: verify_mode,
        server_name_indication: to_charlist(db_host)
      ]
  else
    config :core, Core.Repo,
      username: System.get_env("DB_USER"),
      password: System.get_env("DB_PASS"),
      database: System.get_env("DB_NAME"),
      hostname: System.get_env("DB_HOST"),
      ssl: [
        cacertfile: cacertfile,
        verify: verify_mode,
        server_name_indication: to_charlist(db_host)
      ]
  end

  # END DATABASE

  config :core, GoogleSignIn,
    redirect_uri: "#{base_url}/google-sign-in/auth",
    client_id: System.get_env("GOOGLE_SIGN_IN_CLIENT_ID"),
    client_secret: System.get_env("GOOGLE_SIGN_IN_CLIENT_SECRET")

  config :core, Core.SurfConext,
    redirect_uri: "#{base_url}/surfconext/auth",
    site: System.get_env("SURFCONEXT_SITE"),
    client_id: System.get_env("SURFCONEXT_CLIENT_ID"),
    client_secret: System.get_env("SURFCONEXT_CLIENT_SECRET")

  config :core, SignInWithApple,
    redirect_uri: "#{base_url}/apple/auth",
    client_id: System.get_env("SIGN_IN_WITH_APPLE_CLIENT_ID"),
    team_id: System.get_env("SIGN_IN_WITH_APPLE_TEAM_ID"),
    private_key_id: System.get_env("SIGN_IN_WITH_APPLE_PRIVATE_KEY_ID"),
    private_key_path: System.get_env("SIGN_IN_WITH_APPLE_PRIVATE_KEY_PATH")

  config :core, Core.ImageCatalog.Unsplash,
    access_key: System.get_env("UNSPLASH_ACCESS_KEY"),
    app_name: System.get_env("UNSPLASH_APP_NAME")

  if push_api_key = System.get_env("APPSIGNAL_PUSH_API_KEY") do
    config :appsignal, :config,
      otp_app: :core,
      name: "Next",
      env: app_domain,
      revision: System.get_env("APPSIGNAL_REVISION"),
      push_api_key: push_api_key,
      active: true
  end

  config :core, :storage,
    services:
      System.get_env("STORAGE_SERVICES", "builtin, yoda")
      |> String.split(",", trim: true)
      |> Enum.map(&String.trim/1)
      |> Enum.map(&String.to_atom/1)

  if storage_s3_prefix = System.get_env("STORAGE_S3_PREFIX") do
    config :core, Systems.Storage.BuiltIn, special: Systems.Storage.BuiltIn.S3

    config :core, Systems.Storage.BuiltIn.S3,
      bucket: System.get_env("AWS_S3_BUCKET"),
      prefix: storage_s3_prefix
  else
    config :core, Systems.Storage.BuiltIn, special: Systems.Storage.BuiltIn.LocalFS
  end

  if content_s3_prefix = System.get_env("CONTENT_S3_PREFIX") do
    config :core, :content,
      backend: Systems.Content.S3,
      bucket: System.get_env("PUBLIC_S3_BUCKET"),
      public_url: System.get_env("PUBLIC_S3_URL"),
      prefix: content_s3_prefix
  else
    config :core, :content, backend: Systems.Content.LocalFS
  end

  if feldspar_s3_prefix = System.get_env("FELDSPAR_S3_PREFIX") do
    config :core, :feldspar,
      backend: Systems.Feldspar.S3,
      bucket: System.get_env("PUBLIC_S3_BUCKET"),
      # The public URL must point to the root's (bucket) publicly accessible URL.
      # It should have a policy that allows anonymous users to read all files.
      public_url: System.get_env("PUBLIC_S3_URL"),
      prefix: feldspar_s3_prefix
  else
    config :core, :feldspar, backend: Systems.Feldspar.LocalFS
  end

  config :core,
         :dist_hosts,
         "DIST_HOSTS"
         |> System.get_env("")
         |> String.split(",")
         |> Enum.map(&String.trim/1)
         |> Enum.reject(&(&1 == ""))
         |> Enum.map(&"core@#{&1}")
         |> Enum.map(&String.to_atom/1)
end
