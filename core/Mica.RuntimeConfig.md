# `Mica.RuntimeConfig`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica/runtime_config.ex#L1)

Building blocks for a SaaS's `config/runtime.exs`.

Every helper takes the environment as a map (`System.get_env/0` in
`runtime.exs`, a fixture in tests) and returns plain config values. They read
each setting under one name only, and environment values choose the setup,
never the platform the release runs on.

# `dist_hosts`

Erlang node names (`core@<host>`) for the hosts in `DIST_HOSTS`.

# `features`

Feature flags from `ENABLED_APP_FEATURES`. `:e2e` gates test-only endpoints and
`:storybook` the component catalog; neither is ever enabled when `deploy_env` is `:prod`.

The list can only switch flags on (`Mica.FeatureFlags`). Parsing is kept
exactly as before, empty items included (they become the flag `:""`).

# `fetch!`

Returns the value of `name`, raising like `System.fetch_env!/1` when it is not set.

# `inside?`

Whether `path` is `root` or lies inside it, after expanding both and
resolving symbolic links in their existing parts.

# `list`

Splits a comma-separated value into its trimmed, non-empty items.

# `log_choices`

Logs the setup the runtime config chose, never values: database TLS, mail
adapter, S3 endpoint and cluster size. Warns about unknown Oban plugin names.

# `mailer`

Mailer options: Mailgun when `MAILGUN_API_KEY` is set, otherwise Amazon SES
(with the keys and region from `s3/1`).

Options: `:name` and `:domain` of the app, `:mail_domain` to send from and
`:mailgun_base_uri`.

# `repo`

Repo options from `DATABASE_URL`.

TLS is on when `DB_CA_PATH` is set. It verifies the peer unless
`DB_TLS_VERIFY=verify_none`, and takes the server name for SNI and the
hostname check from the URL host. `ECTO_IPV6=true` (or `1`) connects over IPv6.

# `s3`

`:ex_aws` options: keys and region from the environment, plus an S3 endpoint
when `AWS_ENDPOINT_URL_S3` is set (an S3-compatible store; the keys are then
required and the region defaults to `auto`).

---

*Consult [api-reference.md](api-reference.md) for complete listing*
