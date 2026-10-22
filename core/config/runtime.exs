# Runtime configuration for every deployment (AWS, Fly) and for local
# development. Environment variable values choose the setup, never the
# platform: each setting is read under one name everywhere.
#
# What each environment gets is pinned by the snapshots in
# next/test/config/snapshots/. After a change here, review and update them with
# `mix config.snapshot --update`.
import Config

alias Core.RuntimeConfig

if config_env() == :dev do
  env_file = Path.expand("../.env", __DIR__)

  if File.exists?(env_file) do
    env_file
    |> File.stream!()
    |> Stream.map(&String.trim/1)
    |> Stream.reject(&(&1 == "" or String.starts_with?(&1, "#")))
    |> Stream.map(fn line ->
      line
      |> String.replace_prefix("export ", "")
      |> String.split("=", parts: 2)
    end)
    |> Enum.each(fn
      [key, value] ->
        unquoted =
          value
          |> String.trim()
          |> String.trim_leading(~s("))
          |> String.trim_trailing(~s("))
          |> String.trim_leading("'")
          |> String.trim_trailing("'")

        System.put_env(key, unquoted)

      _ ->
        :ok
    end)
  end

  config :core, base_url: System.get_env("APP_DOMAIN") || "http://localhost:4000"

  config :core, :payment_webhook_base_url, System.get_env("PAYMENT_WEBHOOK_BASE_URL")

  config :core, Systems.Payment.Provider.OPP,
    base_url: System.get_env("OPP_BASE_URL") || "https://api-sandbox.onlinebetaalplatform.nl/v1",
    api_key: System.get_env("OPP_API_KEY"),
    notification_secret: System.get_env("OPP_NOTIFICATION_SECRET"),
    merchant_uid: System.get_env("OPP_MERCHANT_UID"),
    partner_fee_percentage: String.to_integer(System.get_env("OPP_PARTNER_FEE_PERCENTAGE") || "0")

  # Without PAYMENT_PROVIDER, dev.exs keeps payments on the local provider.
  if System.get_env("PAYMENT_PROVIDER") do
    config :core, payment_provider: Core.Config.payment_provider()
  end

  # Unset means no fallback: an untranslated string renders its msgid, which in
  # this app is the raw dotted key. Deliberate on dev/test so gaps are visible.
  config :core, :gettext_fallback_locale, System.get_env("GETTEXT_FALLBACK_LOCALE")
end

if config_env() == :prod do
  env = System.get_env()

  app_name = System.fetch_env!("APP_NAME")
  app_domain = System.fetch_env!("APP_DOMAIN")
  app_mail_domain = System.fetch_env!("APP_MAIL_DOMAIN")
  upload_path = System.fetch_env!("UPLOAD_PATH")

  scheme = "https"
  base_url = "#{scheme}://#{app_domain}"

  config :core,
    domain: app_domain,
    name: app_name,
    base_url: base_url,
    upload_path: upload_path

  # Deployment environment for seed modules. Defaults to :prod for safety.
  deploy_env = System.get_env("DEPLOY_ENV", "prod") |> String.to_atom()
  config :core, :deploy_env, deploy_env

  # UserCheck email validation API key
  if usercheck_api_key = System.get_env("USERCHECK_API_KEY") do
    config :core, Frameworks.UserCheck, api_key: usercheck_api_key
  end

  config :core, :features, RuntimeConfig.features(env, deploy_env)

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
  # Node-local queue for storage delivery (data donation files are on local filesystem)
  # IMPORTANT: Systems.Storage.Private.storage_delivery_queue/0 is the source of truth for this formula.
  # This duplication is required because config runs before modules are loaded.
  storage_delivery_queue = :"storage_delivery_local_#{Node.self()}"

  # The names that ENABLED_OBAN_PLUGINS can switch on. All enabled cron names
  # share one Oban.Plugins.Cron.
  {oban_plugins, oban_unknown_plugins} =
    RuntimeConfig.oban_plugins(env, [
      {"pruner", {:plugin, {Oban.Plugins.Pruner, max_age: 60 * 60}}},
      {"lifeline", {:plugin, {Oban.Plugins.Lifeline, rescue_after: :timer.minutes(60)}}},
      {"advert_expiration", {:cron, {"*/5 * * * *", Systems.Advert.ExpirationWorker}}},
      {"data_donation_cleanup",
       {:cron,
        {System.get_env("FELDSPAR_CLEANUP_SCHEDULE", "0 * * * *"),
         Systems.Feldspar.DataDonationCleanupWorker}}},
      {"pay_in_expiration", {:cron, {"* * * * *", Systems.Fund.PayInExpirationWorker}}},
      {"payment_reconciliation", {:cron, {"0 3 * * *", Systems.Payment.ReconciliationWorker}}},
      {"auth_code_cleanup", {:cron, {"0 * * * *", Systems.Account.AuthCodeCleanupWorker}}},
      {"auto_approve", {:cron, {"0 * * * *", Systems.Fund.AutoApproveWorker}}}
    ])

  config :core, Oban,
    queues: [
      {storage_delivery_queue, 1},
      default: 5,
      email_dispatchers: 1,
      email_delivery: 1,
      ris_import: 1
    ],
    plugins: oban_plugins

  # Logged at boot by Core.Application.
  config :core, :oban_unknown_plugins, oban_unknown_plugins

  # RATE LIMITER

  config :core, :rate, quotas: System.get_env("RATE_QUOTAS", "[]") |> Jason.decode!()

  # MAIL: Mailgun when MAILGUN_API_KEY is set, otherwise Amazon SES.

  config :core,
         Systems.Email.Mailer,
         RuntimeConfig.mailer(env,
           name: app_name,
           domain: app_domain,
           mail_domain: app_mail_domain,
           mailgun_base_uri: "https://api.eu.mailgun.net/v2"
         )

  # EX AWS: AWS S3 and SES, or an S3-compatible store via AWS_ENDPOINT_URL_S3.

  config :ex_aws, RuntimeConfig.s3(env)

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

  # DATABASE: DATABASE_URL; TLS when DB_CA_PATH is set.

  config :core, Core.Repo, RuntimeConfig.repo(env)

  config :core, Systems.Account.Auth.Google,
    redirect_uri: "#{base_url}/auth/google/callback",
    client_id: System.get_env("GOOGLE_SIGN_IN_CLIENT_ID"),
    client_secret: System.get_env("GOOGLE_SIGN_IN_CLIENT_SECRET")

  config :core, Systems.Account.Auth.Surfconext,
    redirect_uri: "#{base_url}/auth/surfconext/callback",
    base_url: System.get_env("SURFCONEXT_SITE"),
    client_id: System.get_env("SURFCONEXT_CLIENT_ID"),
    client_secret: System.get_env("SURFCONEXT_CLIENT_SECRET")

  config :core, Systems.Account.Auth.Centerdata,
    redirect_uri: "#{base_url}/auth/centerdata/callback",
    base_url: System.get_env("CENTERDATA_SITE", "https://messpanel.test.centerdata.nl"),
    client_id: System.get_env("CENTERDATA_CLIENT_ID"),
    client_secret: System.get_env("CENTERDATA_CLIENT_SECRET"),
    authorization_params: [scope: "email"],
    client_authentication_method: "client_secret_post",
    code_verifier: true

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
      System.get_env("STORAGE_SERVICES", "builtin, yoda")
      |> RuntimeConfig.list()
      |> Enum.map(&String.to_atom/1)

  if storage_s3_prefix = System.get_env("STORAGE_S3_PREFIX") do
    config :core, Systems.Storage.BuiltIn, special: Systems.Storage.BuiltIn.S3

    storage_s3_bucket = System.fetch_env!("AWS_S3_BUCKET")

    # Donations need a private bucket: PUBLIC_S3_BUCKET is publicly readable.
    if storage_s3_bucket == System.get_env("PUBLIC_S3_BUCKET") do
      raise "AWS_S3_BUCKET (#{storage_s3_bucket}) must be a private bucket, not PUBLIC_S3_BUCKET"
    end

    config :core, Systems.Storage.BuiltIn.S3,
      bucket: storage_s3_bucket,
      prefix: storage_s3_prefix
  else
    config :core, Systems.Storage.BuiltIn, special: Systems.Storage.BuiltIn.LocalFS

    # Donations must stay out of UPLOAD_PATH: that folder is served without
    # authentication at /uploads and /feldspar/apps. Defaults to a `storage`
    # folder next to it.
    upload_path = Path.expand(upload_path)

    storage_path =
      System.get_env("STORAGE_PATH", Path.join(Path.dirname(upload_path), "storage"))
      |> Path.expand()

    if RuntimeConfig.inside?(storage_path, upload_path) do
      raise "STORAGE_PATH (#{storage_path}) must not be inside UPLOAD_PATH (#{upload_path})"
    end

    config :core, Systems.Storage.BuiltIn.LocalFS, root_path: storage_path
  end

  if content_s3_prefix = System.get_env("CONTENT_S3_PREFIX") do
    config :core, :content,
      backend: Systems.Content.S3,
      bucket: System.fetch_env!("PUBLIC_S3_BUCKET"),
      public_url: System.fetch_env!("PUBLIC_S3_URL"),
      prefix: content_s3_prefix
  else
    config :core, :content, backend: Systems.Content.LocalFS
  end

  if feldspar_s3_prefix = System.get_env("FELDSPAR_S3_PREFIX") do
    config :core, :feldspar,
      backend: Systems.Feldspar.S3,
      bucket: System.fetch_env!("PUBLIC_S3_BUCKET"),
      # The public URL must point to the root's (bucket) publicly accessible URL.
      # It should have a policy that allows anonymous users to read all files.
      public_url: System.fetch_env!("PUBLIC_S3_URL"),
      prefix: feldspar_s3_prefix
  else
    config :core, :feldspar, backend: Systems.Feldspar.LocalFS
  end

  config :core, :paper,
    import_batch_size:
      System.get_env("PAPER_RIS_IMPORT_BATCH_SIZE", "100") |> String.to_integer(),
    import_batch_timeout:
      System.get_env("PAPER_RIS_IMPORT_BATCH_TIMEOUT", "30000") |> String.to_integer(),
    # Maximum allowed RIS file size (default 150MB, supports ~100,000 paper references)
    ris_max_file_size:
      System.get_env("PAPER_RIS_MAX_FILE_SIZE", "157286400") |> String.to_integer(),
    # Chunk size for streaming RIS files (default 64KB)
    # Smaller chunks (8KB-32KB): Better for unreliable networks, lower memory usage
    # Larger chunks (128KB-1MB): Better for fast networks, reduces overhead for large files
    ris_stream_chunk_size:
      System.get_env("PAPER_RIS_STREAM_CHUNK_SIZE", "65536") |> String.to_integer()

  # Data donation temporary file storage
  # Files are stored here before being delivered to the final storage endpoint
  # Default retention is 2 weeks (336 hours), configurable via FELDSPAR_DATA_DONATION_RETENTION
  config :core, :feldspar_data_donation,
    path: System.fetch_env!("FELDSPAR_DATA_DONATION_PATH"),
    retention_hours:
      System.get_env("FELDSPAR_DATA_DONATION_RETENTION", "336") |> String.to_integer()

  config :core, :dist_hosts, RuntimeConfig.dist_hosts(env)

  config :core, Systems.Payment.Provider.OPP,
    base_url: System.get_env("OPP_BASE_URL"),
    api_key: System.get_env("OPP_API_KEY"),
    notification_secret: System.get_env("OPP_NOTIFICATION_SECRET"),
    merchant_uid: System.get_env("OPP_MERCHANT_UID"),
    partner_fee_percentage: String.to_integer(System.get_env("OPP_PARTNER_FEE_PERCENTAGE") || "0")

  config :core, payment_provider: Core.Config.payment_provider()

  config :core,
    auto_approve_timeout: System.get_env("AUTO_APPROVE_TIMEOUT", "14") |> String.to_integer()

  # SERVICE LOGIN API
  # Required for /api/service/login endpoint (load testing, integrations)
  if service_login_key = System.get_env("SERVICE_LOGIN_KEY") do
    config :core, :service_login, key: service_login_key
  end

  # Unset means no fallback: an untranslated string renders its msgid, which in
  # this app is the raw dotted key. Deliberate on dev/test so gaps are visible.
  config :core, :gettext_fallback_locale, System.get_env("GETTEXT_FALLBACK_LOCALE")

  # Mock sign-in for test environments; never on production.
  if deploy_env != :prod do
    auth_methods =
      Application.get_env(:core, :account, [])
      |> Keyword.get(:auth_methods, %{})
      |> Map.put(:mock, %{provider: true, satellite: false})

    config :core, :account, auth_methods: auth_methods
  end
end
