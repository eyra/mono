# Known differences between the environment names production and staging set,
# with the reason each is accepted. scripts/env_names.exs fails on a difference
# that is not listed here, and reports entries that are no longer a difference.
%{
  # Read by the release, set on production only
  "DB_CA_PATH" =>
    "production connects to RDS over TLS; staging's database is on Fly's private network",
  "DB_TLS_VERIFY" => "goes with DB_CA_PATH",
  "DIST_HOSTS" => "production is a two-node cluster; staging machines are not clustered",
  "RELEASE_COOKIE" => "goes with DIST_HOSTS",
  "PAPER_RIS_IMPORT_BATCH_SIZE" =>
    "the production unit sets it when the inventory defines it; staging uses the default",
  "PAPER_RIS_IMPORT_BATCH_TIMEOUT" =>
    "the production unit sets it when the inventory defines it; staging uses the default",
  "PAPER_RIS_MAX_FILE_SIZE" =>
    "the production unit sets it when the inventory defines it; staging uses the default",
  "PAPER_RIS_STREAM_CHUNK_SIZE" =>
    "the production unit sets it when the inventory defines it; staging uses the default",
  "RATE_QUOTAS" =>
    "the production unit sets it when the inventory defines it; staging uses the systems' default quotas",
  "STORAGE_UPLOAD_MAX_SIZE" =>
    "the production unit sets it when the inventory defines it; staging uses the default",

  # Read by the release, set on staging only
  "AWS_ENDPOINT_URL_S3" => "staging stores files in Tigris, production in AWS S3",
  "DEPLOY_ENV" => "unset means prod, which is what production needs",
  "ECTO_IPV6" => "Fly's private network is IPv6",
  "MAILGUN_API_KEY" => "staging sends mail with Mailgun, production with Amazon SES",
  "OPP_BASE_URL" =>
    "staging uses the OPP sandbox; the production unit template sets no OPP names",
  "SERVICE_LOGIN_KEY" => "the service login (load tests) is off on production",
  "STORAGE_SERVICES" => "staging offers builtin storage only; production the default list",

  # Set on production, never read at runtime: names from before the one-name
  # runtime config (see the Flux issue on the old env names)
  "DB_HOST" => "old name; the release reads DATABASE_URL",
  "DB_NAME" => "old name; the release reads DATABASE_URL",
  "DB_PASS" => "old name; the release reads DATABASE_URL",
  "DB_URL" => "old name; the release reads DATABASE_URL",
  "DB_USER" => "old name; the release reads DATABASE_URL",
  "HTTPS_PORT" => "not read: TLS ends at nginx",
  "LOG_LEVEL" => "not read: prod.exs sets the log level",
  "RELEASE_ENV" => "not read by the release",
  "SSL_DOMAINS" => "not read by the release",
  "SIGN_IN_WITH_APPLE_CLIENT_ID" => "not read: no Sign in with Apple in the release",
  "SIGN_IN_WITH_APPLE_PRIVATE_KEY_ID" => "not read: no Sign in with Apple in the release",
  "SIGN_IN_WITH_APPLE_PRIVATE_KEY_PATH" => "not read: no Sign in with Apple in the release",
  "SIGN_IN_WITH_APPLE_TEAM_ID" => "not read: no Sign in with Apple in the release",
  "WEB_PUSH_PRIVATE_KEY" => "not read: no web push in the release",
  "WEB_PUSH_PUBLIC_KEY" => "not read: no web push in the release",
  "STATIC_PATH" => "not read: static files are served from UPLOAD_PATH (set on both)",

  # Set on staging, never read at runtime
  "BUCKET_NAME" =>
    "set by Fly's Tigris integration; the release reads PUBLIC_S3_BUCKET and AWS_S3_BUCKET",
  "PHX_HOST" => "not read: the release reads APP_DOMAIN"
}
