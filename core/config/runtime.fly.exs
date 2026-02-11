# Fly.io Runtime Configuration
# This file is loaded when FLY_APP_NAME is set (i.e., running on Fly.io)

import Config

if config_env() == :prod do
  # FLY_APP_NAME is set automatically by Fly.io (e.g., "eyra-next-test1")
  fly_app_name = System.fetch_env!("FLY_APP_NAME")

  # Derive defaults from FLY_APP_NAME, allow overrides via env vars
  app_domain = System.get_env("APP_DOMAIN") || "#{fly_app_name}.fly.dev"
  app_name = System.get_env("APP_NAME") || fly_app_name
  app_mail_domain = System.get_env("APP_MAIL_DOMAIN") || "eyra.dev"
  app_mail_noreply = "no-reply@#{app_mail_domain}"
  upload_path = System.fetch_env!("UPLOAD_PATH")

  scheme = "https"
  base_url = "#{scheme}://#{app_domain}"

  config :core,
    domain: app_domain,
    name: app_name,
    base_url: base_url,
    upload_path: upload_path

  # Allow enabling of features from an environment variable
  config :core,
         :features,
         System.get_env("ENABLED_APP_FEATURES", "")
         |> String.split(~r"\s*,\s*")
         |> Enum.map(&String.to_atom/1)
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
      ip: {0, 0, 0, 0},
      port: String.to_integer(System.get_env("HTTP_PORT", "8000"))
    ]

  # PHOENIX LIVE UPLOAD

  config :core, CoreWeb.FileUploader,
    max_file_size: System.get_env("STORAGE_UPLOAD_MAX_SIZE", "100000000") |> String.to_integer()

  # OBAN
  storage_delivery_queue = :"storage_delivery_local_#{Node.self()}"

  oban_plugins =
    System.get_env("ENABLED_OBAN_PLUGINS", "")
    |> String.split(~r"\s*,\s*")

  config :core, Oban,
    queues: [
      {storage_delivery_queue, 1},
      default: 5,
      email_dispatchers: 1,
      email_delivery: 1,
      ris_import: 1
    ],
    plugins:
      Enum.map(oban_plugins, fn plugin ->
        case plugin do
          "pruner" ->
            {Oban.Plugins.Pruner, max_age: 60 * 60}

          "lifeline" ->
            {Oban.Plugins.Lifeline, rescue_after: :timer.minutes(60)}

          "advert_expiration" ->
            {Oban.Plugins.Cron, crontab: [{"*/5 * * * *", Systems.Advert.ExpirationWorker}]}

          "data_donation_cleanup" ->
            cleanup_schedule = System.get_env("FELDSPAR_CLEANUP_SCHEDULE", "0 * * * *")

            {Oban.Plugins.Cron,
             crontab: [
               {cleanup_schedule, Systems.Feldspar.DataDonationCleanupWorker,
                queue: storage_delivery_queue}
             ]}

          _ ->
            nil
        end
      end)
      |> Enum.reject(&is_nil/1)

  # RATE LIMITER

  config :core, :rate, quotas: System.get_env("RATE_QUOTAS", "[]") |> Jason.decode!()

  # MAILGUN (optional)

  if mailgun_api_key = System.get_env("MAILGUN_API_KEY") do
    config :core, Systems.Email.Mailer,
      adapter: Bamboo.MailgunAdapter,
      base_uri: "https://api.eu.mailgun.net/v2",
      api_key: mailgun_api_key,
      domain: app_domain,
      default_from_email: "#{app_name} <#{app_mail_noreply}>",
      hackney_opts: [recv_timeout: :timer.minutes(1)]
  end

  # =============================================================================
  # FLY POSTGRES
  # Fly automatically sets DATABASE_URL when you attach a Postgres cluster
  # =============================================================================

  config :core, Core.Repo,
    url: System.fetch_env!("DATABASE_URL"),
    socket_options: if(System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: [])

  # =============================================================================
  # TIGRIS OBJECT STORAGE (S3-compatible)
  # Fly automatically sets these when you attach a Tigris bucket:
  # - AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
  # - AWS_ENDPOINT_URL_S3, AWS_REGION, BUCKET_NAME
  # =============================================================================

  if s3_endpoint = System.get_env("AWS_ENDPOINT_URL_S3") do
    config :ex_aws,
      access_key_id: System.fetch_env!("AWS_ACCESS_KEY_ID"),
      secret_access_key: System.fetch_env!("AWS_SECRET_ACCESS_KEY"),
      region: System.get_env("AWS_REGION", "auto")

    endpoint_uri = URI.parse(s3_endpoint)

    config :ex_aws, :s3,
      scheme: "#{endpoint_uri.scheme}://",
      host: endpoint_uri.host,
      port: endpoint_uri.port || 443
  end

  # =============================================================================
  # SHARED CONFIGURATION
  # =============================================================================

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

  # STORAGE BACKENDS

  config :core, :storage,
    services:
      System.get_env("STORAGE_SERVICES", "builtin")
      |> String.split(",", trim: true)
      |> Enum.map(&String.trim/1)
      |> Enum.map(&String.to_atom/1)

  if storage_s3_prefix = System.get_env("STORAGE_S3_PREFIX") do
    config :core, Systems.Storage.BuiltIn, special: Systems.Storage.BuiltIn.S3

    config :core, Systems.Storage.BuiltIn.S3,
      bucket: System.get_env("BUCKET_NAME"),
      prefix: storage_s3_prefix
  else
    config :core, Systems.Storage.BuiltIn, special: Systems.Storage.BuiltIn.LocalFS
  end

  if content_s3_prefix = System.get_env("CONTENT_S3_PREFIX") do
    config :core, :content,
      backend: Systems.Content.S3,
      bucket: System.get_env("BUCKET_NAME"),
      public_url: System.get_env("PUBLIC_S3_URL"),
      prefix: content_s3_prefix
  else
    config :core, :content, backend: Systems.Content.LocalFS
  end

  if feldspar_s3_prefix = System.get_env("FELDSPAR_S3_PREFIX") do
    config :core, :feldspar,
      backend: Systems.Feldspar.S3,
      bucket: System.get_env("BUCKET_NAME"),
      public_url: System.get_env("PUBLIC_S3_URL"),
      prefix: feldspar_s3_prefix
  else
    config :core, :feldspar, backend: Systems.Feldspar.LocalFS
  end

  config :core, :paper,
    import_batch_size:
      System.get_env("PAPER_RIS_IMPORT_BATCH_SIZE", "100") |> String.to_integer(),
    import_batch_timeout:
      System.get_env("PAPER_RIS_IMPORT_BATCH_TIMEOUT", "30000") |> String.to_integer(),
    ris_max_file_size:
      System.get_env("PAPER_RIS_MAX_FILE_SIZE", "157286400") |> String.to_integer(),
    ris_stream_chunk_size:
      System.get_env("PAPER_RIS_STREAM_CHUNK_SIZE", "65536") |> String.to_integer()

  config :core, :feldspar_data_donation,
    path: System.fetch_env!("FELDSPAR_DATA_DONATION_PATH"),
    retention_hours:
      System.get_env("FELDSPAR_DATA_DONATION_RETENTION", "336") |> String.to_integer()

  # No clustering for dev environment (single node)
  config :core, :dist_hosts, []

  # SERVICE LOGIN API
  # Required for /api/service/login endpoint (load testing, integrations)
  if service_login_key = System.get_env("SERVICE_LOGIN_KEY") do
    config :core, :service_login, key: service_login_key
  end
end
