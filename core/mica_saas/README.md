# Self: the reference SaaS on Mica

Self is a self-hostable SaaS built on Mica. In this repository it lives in `core/mica_saas/` (future repository `novasoftwarefoundation/mica-saas`). It is selected at build time with `BUNDLE=self`, which imports `config/config.exs` (`config :core, saas: Self.SaaS`). `lib/saas.ex` (`Self.SaaS`, a `Core.SaaS`) lists the systems Self is made of and its SaaS-level config: start pages, menus, title and signed-in pages. Self's own systems live in `systems/`, such as `systems/account/` (`Self.Account.System`, a `Core.System`) with the sign-in pages.

All commands below run from the `core/` folder unless stated otherwise.

## Development instructions

### Setup

0. Pre-requisite

    * Install [asdf](https://asdf-vm.com)
    * Install [PostgreSQL Server](https://www.postgresql.org)
    * Fork and clone branch `master` of this Mono repo.
	* Register application on [Unsplash](https://unsplash.com/) which is used as an Image Catalog.

1. Create a PostgreSQL database and replace the configurated values in `core/config/dev.exs` with your own:

    ```Elixir
    # Configure your database
    config :core, Core.Repo,
    username: "postgres",
    password: "postgres",
    database: "self_dev",
    ```

2. Install tools:

    ```sh
    $ asdf plugin add erlang
    $ asdf plugin add elixir
    $ asdf plugin add nodejs

    $ asdf install
    ```

    See `.tool-versions` for the exact versions that will be installed

3. Setup:

    ```sh
    $ cd core
    $ mix setup
    ```

4. Build Core (from core folder):

    ```sh
    $ BUNDLE=self mix compile
    ```

5. Run Core locally (from core folder):

    ```sh
    $ BUNDLE=self mix phx.server
    ```

6. Go to browser

    The Core app is running at: http://localhost:4000


## Customizing

### Branding

* Replace [self.svg](../priv/static/images/logos/products/self.svg) and [self_wide.svg](../priv/static/images/logos/products/self_wide.svg) with your icons of choice.
* Change [footer.ex](../mica/frameworks/pixel/components/footer.ex) to format the platform footer or remove it completely

### Menu items

* In [items.ex](lib/menu/items.ex) you will find all the menu items. Add custom items when required.

Core supports the following page layouts:
* Stripped: minimalistic page without menu
* Website: menu at the top
* Workspace: menu on the left

Change the menus here:
* [Stripped](lib/layouts/stripped/menu_builder.ex)
* [Website](lib/layouts/website/menu_builder.ex)
* [Workspace](lib/layouts/workspace/menu_builder.ex)

### Storage

The platform supports pluggable backends for global (non-study-specific) temporary file storage using the `Systems.Storage.BuiltIn.Special` interface. This storage is used, for example, in data donation workflows.

Although these files are temporary, the system must guarantee that they are stored reliably. We recommend using production-ready backends such as **S3** or **Azure Blob**.

#### Available built-in backends

- `Systems.Storage.BuiltIn.S3`
- `Systems.Storage.BuiltIn.LocalFS`

You can configure the backend via environment variables. The active backend is set via:

```bash
STORAGE_BUILTIN_SPECIAL=s3   # or my_backend
```

#### 🛠️ Creating Your Own Backend

To add a custom backend, define a module implementing the following behaviour:

```elixir
defmodule Systems.Storage.BuiltIn.Special do
  @callback store(
              folder :: binary(),
              identifier :: list(tuple()) | binary(),
              data :: binary()
            ) :: any()

  @callback list_files(folder :: binary()) :: list()
  @callback delete_files(folder :: binary()) :: :ok | {:error, atom()}
end
```

You can add your implementation in:

```
core/mica/systems/storage/builtin/my_backend.ex
```

Minimal example:

```elixir
defmodule Systems.Storage.BuiltIn.MyBackend do
  @behaviour Systems.Storage.BuiltIn.Special

  def store(folder, filename, data) do
    # Your custom storage logic here
  end

  def list_files(_folder), do: []
  def delete_files(_folder), do: :ok

  # Configuration

  defp config do
    Application.fetch_env!(:core, Systems.Storage.BuiltIn.MyBackend)
  end

  defp var_1 do
    Access.get(config(), :var_1, 256)
  end

  defp var_2 do
    Access.get(config(), :var_2, "default")
  end

  defp var_n do
    Access.get(config(), :var_n, "https://mybackend.com") |> URI.parse()
  end
end
```
The `list_files/1` and `delete_files/1` functions can be implemented as no-ops if the platform’s file export functionality in the user interface is not used, and files are instead accessed directly at the final storage location — for example, when using Yoda.

Prevent any hardcoded variable but use the Elixir configuration system to retreive runtime values.


#### AWS S3 example

An S3 example can be found in:

```
core/mica/systems/storage/builtin/s3.ex
```
Below a code snippet:
```elixir
def store(folder, filename, data) do
  filepath = Path.join(folder, filename)
  object_key = object_key(filepath)
  content_type = content_type(object_key)
  bucket = Access.fetch!(settings(), :bucket)

  S3.put_object(bucket, object_key, data, content_type: content_type)
  |> backend().request!()
end
```

#### ⚙️ Configuration

To activate and configure a storage backend, you must modify the runtime configuration, `core/config/runtime.exs`.

The current default runtime configuration is to use `Systems.Storage.BuiltIn.S3` when there is a
`STORAGE_S3_PREFIX` environment variable configurated. Fallback storage is `Systems.Storage.BuiltIn.LocalFS`, which
stores donations in `STORAGE_PATH` (default: a `storage` folder next to `UPLOAD_PATH`). Researchers download
them through the endpoint export, which checks access. `STORAGE_PATH` must not be inside `UPLOAD_PATH`: that
folder is served without authentication, and the app refuses to start with such a setting.

Upgrading from a version that stored donations in `UPLOAD_PATH`: the app refuses to start while `UPLOAD_PATH`
still holds endpoint folders (named `project_node=<id>`, or `assignment=<id>` for endpoints created before storage
moved to projects in mid-2024), because they would stay public and researchers could not export them. The error lists
the first folders (with the total) and the commands that move them, with the actual paths filled in: one `mv`
per prefix that has folders, so the commands stay short however many folders there are. For example:

```sh
mkdir -p /home/next/storage
mv /home/next/uploads/assignment=*/ /home/next/storage/
mv /home/next/uploads/project_node=*/ /home/next/storage/
```

Stop the app on every node, run those commands, then start the app again.

With `MIX_ENV=prod` the error is logged as one JSON line, with its line breaks escaped, so the app also writes it
to stderr once as plain text, just before it stops. Copy the commands from there.

A donation folder that is a symlink to a folder elsewhere gets its own `mv` without the trailing slash, for example
`mv /home/next/uploads/project_node=34 /home/next/storage/`, listed before the prefix globs so they no longer match
it. With more than 10 such links, one `for` loop per prefix moves them all instead. The link itself moves, its target
stays where it is: check targets first. A relative target must still resolve from `STORAGE_PATH`, and a target inside
`UPLOAD_PATH` stays public and is not checked again, so replace such a link with the folder it points to.

The app never moves the files itself. Installations on S3 storage (`STORAGE_S3_PREFIX` set) are not checked.

```elixir
  if storage_s3_prefix = System.get_env("STORAGE_S3_PREFIX") do
    config :core, Systems.Storage.BuiltIn, special: Systems.Storage.BuiltIn.S3

    config :core, Systems.Storage.BuiltIn.S3,
      bucket: System.get_env("AWS_S3_BUCKET"),
      prefix: storage_s3_prefix
  else
    config :core, Systems.Storage.BuiltIn, special: Systems.Storage.BuiltIn.LocalFS
  end
```

That config can be replace by:

```elixir
  if my_backend = System.get_env("STORAGE_BUILTIN_SPECIAL") do
    config :core, Systems.Storage.BuiltIn, special: String.to_atom(my_backend)
  end

  config Systems.Storage.BuiltIn.MyBackend,
    var_1: System.get_env("STORAGE_BUILTIN_MYBACKEND_VAR1") |> String.integer(),
    var_2: System.get_env("STORAGE_BUILTIN_MYBACKEND_VAR2")
    var_n: System.get_env("STORAGE_BUILTIN_MYBACKEND_VARN")
```

Your environent variables should contain something like this:

```bash
STORAGE_BUILTIN_SPECIAL=Systems.Storage.Builtin.MyBackend
STORAGE_BUILTIN_MYBACKEND_MYVAR1=1024
STORAGE_BUILTIN_MYBACKEND_MYVAR2=string value
STORAGE_BUILTIN_MYBACKEND_MYVARN=https://client1.mybackend.com
```

#### 🚧 Roadmap: UX-based File Transfer

We plan to support file transfer from the built-in storage to external systems (e.g., Yoda) via the user interface. Until then, this must be done manually or with automation.

### Rate limiters

To prevent users from exhausting resources, Core uses rate limiters. The systems declare the default
quotas of the services they limit (`rate_quotas/0` in their `_system.ex`). A service without any
quota is not limited.

Overrides replace the default quotas of the services they list; the other services keep their
defaults. In a release, set them with the `RATE_QUOTAS` environment variable, a JSON list:

```bash
RATE_QUOTAS='[{"service": "signup", "limit": 10, "unit": "call", "window": "minute", "scope": "local"}]'
```

Locally, `core/config/dev.exs` sets them with `quota_overrides:`:

```Elixir
config :core, :rate,
  prune_interval: 5 * 60 * 1000,
  quota_overrides: [
    [service: "storage_export", limit: 1, unit: "call", window: "hour", scope: "local"]
  ]
```

Setting `quotas:` in an environment config replaces all defaults (`test.exs` does this on purpose),
and every service it leaves out is no longer limited.

## Deploying on Fly.io

Self runs as a Fly.io app. Eyra runs nova-mica-dev, an internal development server whose only
purpose is to keep this code alive; it is not a service for others or a public demo.
[`fly.mica-dev.toml`](../fly.mica-dev.toml) holds its configuration, and
[`fly-deploy-mica-dev.yml`](../../.github/workflows/fly-deploy-mica-dev.yml) deploys every push
to `develop` and then smoke tests the start page, `/user/signin` and `/.status/health`. You can
use both files as a template for your own deployment. Machines stop when idle and start on the next
request. For a while, nova-mica-dev also serves as the rehearsal environment for the container
image build (step `build-image` in `docs/nova-migration/plan.md`).

The image is built from [`core/Dockerfile`](../Dockerfile) with the build arguments
`BUNDLE=self`, `PLATFORM=fly` (selects `config/runtime.fly.exs`), `VERSION` and `GIT_COMMIT`.
Set `FORCE_SSL=false` on Fly: the proxy terminates TLS and the health checks use HTTP.

### One-time setup

Run from the `core/` folder, with your own app name instead of `my-self`:

```sh
flyctl apps create my-self
flyctl postgres create --name my-self-db --region ams --vm-size shared-cpu-1x --volume-size 1 --initial-cluster-size 1
flyctl postgres attach my-self-db --app my-self               # sets DATABASE_URL
flyctl storage create --app my-self --name my-self-storage --public   # sets AWS_* and BUCKET_NAME
flyctl storage create --name my-self-donations                       # private, for donations
flyctl secrets set --app my-self --stage \
  SECRET_KEY_BASE="$(openssl rand -base64 64 | tr -d '\n')" \
  AWS_S3_BUCKET=my-self-donations PUBLIC_S3_BUCKET=my-self-storage
flyctl deploy --remote-only -c fly.my-self.toml --build-arg VERSION=1.0.0 --build-arg PLATFORM=fly
```

Donations must go to a private bucket, separate from the public one: anyone can read objects in
`PUBLIC_S3_BUCKET`, and the app refuses to start when `AWS_S3_BUCKET` is the same bucket. The access
key that `flyctl storage create --app` sets must also be allowed to read and write the donations
bucket; grant that in the Tigris dashboard (`flyctl storage dashboard`).

For automatic deploys, create a deploy token with `flyctl tokens create deploy --app my-self` and
store it as a GitHub Actions secret (`FLY_API_TOKEN_MICA_DEV` for nova-mica-dev).

### Configuration

Each setting has one name. Secrets are set with `flyctl secrets set`; everything else goes in
the `[env]` section of the Fly config.

Required:

| Variable | Kind | Description | Reference value |
|---|---|---|---|
| `DATABASE_URL` | secret | PostgreSQL connection URL; set by `flyctl postgres attach` | |
| `SECRET_KEY_BASE` | secret | Random string of at least 64 characters | `openssl rand -base64 64` |
| `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_ENDPOINT_URL_S3`, `AWS_REGION` | secret | S3 credentials and endpoint; set by `flyctl storage create` | |
| `AWS_S3_BUCKET` | secret | Private bucket for donations; must not be `PUBLIC_S3_BUCKET` | `nova-mica-dev-donations` |
| `PUBLIC_S3_BUCKET` | secret | Public bucket for content and Feldspar apps | `nova-mica-dev-storage` |
| `BUCKET_NAME` | secret | Set by `flyctl storage create`; still read by `runtime.fly.exs` until it moves to `AWS_S3_BUCKET` | `nova-mica-dev-storage` |
| `APP_NAME` | env | Name shown in the UI and in mail | `Mica [dev]` |
| `APP_DOMAIN` | env | Public host name | `nova-mica-dev.fly.dev` |
| `PHX_HOST` | env | Same as `APP_DOMAIN` | `nova-mica-dev.fly.dev` |
| `APP_MAIL_DOMAIN` | env | Domain of the no-reply sender address; must be a domain of your Mailgun account | `next.dev.eyra.co` (Next dev's Mailgun domain, until Nova has its own) |
| `DEPLOY_ENV` | env | Selects the seeds: `dev`, `test`, `staging` or `prod`. Anything but `prod` also enables mock sign-in | `dev` |
| `PAYMENT_PROVIDER` | env | `local` (logs only, no real payments) or `opp` | `local` |
| `ENABLED_APP_FEATURES` | env | Comma-separated feature flags. Self uses `password_sign_in` and `otp` (sign-in with a one-time code by e-mail, at `/user/auth/identify`) | `password_sign_in, otp` |
| `HTTP_PORT` | env | Port the app listens on | `8000` |
| `ECTO_IPV6` | env | `true` on Fly, for `.internal` DNS | `true` |
| `UPLOAD_PATH`, `STATIC_PATH` | env | Upload folder on the mounted volume | `/app/data/uploads` |
| `FELDSPAR_DATA_DONATION_PATH` | env | Data donation folder on the mounted volume | `/app/data/datadonation` |

Optional:

| Variable | Kind | Description | Reference value |
|---|---|---|---|
| `APP_ADMINS` | env or secret | Space-separated e-mail addresses of system admins; wildcards like `*@example.org` work | unset |
| `MAILGUN_API_KEY` | secret | Sends mail through Mailgun (EU). Without it no mail leaves the app, so sign-up confirmation and sign-in code mails do not arrive | Next dev's Mailgun key, for now |
| `STORAGE_SERVICES` | env | Comma-separated storage services | `builtin` |
| `STORAGE_PATH` | env | Donation folder when `STORAGE_S3_PREFIX` is unset; must not be inside `UPLOAD_PATH` | next to `UPLOAD_PATH` (`/app/data/storage`) |
| `STORAGE_S3_PREFIX`, `CONTENT_S3_PREFIX`, `FELDSPAR_S3_PREFIX` | env | Object prefixes; without them the app stores files on the local filesystem | `storage`, `content`, `feldspar` |
| `PUBLIC_S3_URL` | env | Public URL of the public bucket | `https://fly.storage.tigris.dev/nova-mica-dev-storage` |
| `FELDSPAR_DATA_DONATION_RETENTION` | env | Hours to keep data donation files | `336` |
| `ENABLED_OBAN_PLUGINS` | env | Comma-separated: `pruner`, `lifeline` and others in `runtime.fly.exs` | `pruner, lifeline` |
| `GOOGLE_SIGN_IN_CLIENT_ID`, `GOOGLE_SIGN_IN_CLIENT_SECRET` | secret | Your own Google OAuth client | unset |
| `SURFCONEXT_SITE`, `SURFCONEXT_CLIENT_ID`, `SURFCONEXT_CLIENT_SECRET` | secret | Your own SURFconext client | unset |
| `UNSPLASH_ACCESS_KEY`, `UNSPLASH_APP_NAME` | secret | Your own Unsplash app, for the image catalog | unset |
| `APPSIGNAL_PUSH_API_KEY` | secret | AppSignal monitoring | unset |
| `RATE_QUOTAS` | env | JSON list of rate limiter quotas. Replaces the default quotas (the systems' `rate_quotas/0`) of the services it lists; the other services keep their defaults | `[]` |
| `AUTH_CODE_LIMITS` | env | JSON list of sign-in code limits, e.g. `[{"action": "check", "by": "email_network", "limit": 20, "window": "hour"}]` (`action`: `request` or `check`; `by`: `email` (per email address, across network addresses), `email_network` (per email address and network address) or `network` (per network address); `window`: `minute`, `hour` or `day`). `limit` must be a positive integer. Defaults: `request` 10 per hour per `email_network`, 50 per day per `email`, 200 per hour per `network`; `check` 10 per hour and 30 per day per `email_network`, 100 per day per `email`, 200 per hour per `network`. Replaces the default limit (`Systems.Account.AuthCodeLimits`) with the same action, count and window; the other limits keep their defaults, so setting `check`/`email_network` per hour keeps its 30 per day cap. A window without a default adds a limit; a default can be raised but not removed | unset |
| `TRUSTED_PROXIES` | env | Comma-separated addresses or CIDR ranges of the proxies in front of the app. Only a request from one of them has its client address read from `X-Forwarded-For`, which the proxy must set or append to. Replaces the default (the loopback and private ranges), so list those too if a proxy uses them. List only your own proxies, and only proxies that set or append to `X-Forwarded-For`; otherwise a client can choose the address it is counted as. Set it when a CDN or a load balancer with a public address forwards to the app; otherwise every user counts as that proxy's address for the sign-in code limits | unset |
| `GETTEXT_FALLBACK_LOCALE` | env | Locale for untranslated strings. Unset renders the raw keys, which makes missing translations visible | unset |

nova-mica-dev uses no Eyra OAuth clients: every integration above that is unset stays
disabled. For now it sends mail with Next dev's Mailgun key and the `next.dev.eyra.co` sender domain; a
neutral Nova mail domain replaces both later.
