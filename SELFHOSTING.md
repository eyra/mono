# Self hosting

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
    $ asdf plugin-add erlang
    $ asdf plugin-add elixir
    $ asdf plugin-add nodejs

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

* Replace [self.svg](core/assets/static/images/icons/self.svg) and [self_wide.svg](core/assets/static/images/icons/self_wide.svg) with your icons of choice.
* Change [footer.ex](core/lib/core_web/ui/footer.ex) to format the platform footer or remove it completely

### Menu items

* In [items.ex](core/bundles/self/lib/menu/items.ex) you will find all the menu items. Add custom items when required.

Core supports the following page layouts:
* Stripped: minimalistic page without menu
* Website: menu at the top
* Workspace: menu on the left

Change the menus here:
* [Stripped](core/bundles/self/lib/layouts/stripped/menu_builder.ex)
* [Website](core/bundles/self/lib/layouts/website/menu_builder.ex)
* [Workspace](core/bundles/self/lib/layouts/workspace/menu_builder.ex)

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
core/systems/storage/builtin/my_backend.ex
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
core/systems/storage/builtin/s3.ex
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

To activate and configure a storage backend, you must modify the `core/config/runtime.exs` file.

The current default runtime configuration is to use `Systems.Storage.BuiltIn.S3` when there is a
`STORAGE_S3_PREFIX` environment variable configurated. Fallback storage is `Systems.Storage.BuiltIn.LocalFS`.

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

To prevent users from exhausting resources on external services, Core uses rate limiters. The local configuration of rate limiters can be found in `core/config/dev.exs`:

```Elixir
config :core, :rate,
  prune_interval: 5 * 1000,
  quotas: [
    [service: :azure_blob, limit: 1, unit: :call, window: :second, scope: :local],
    [service: :azure_blob, limit: 100, unit: :byte, window: :second, scope: :local]
  ]
```

.. and the production configuration can be found in `core/config/config.exs`:

```Elixir
config :core, :rate,
  prune_interval: 60 * 60 * 1000,
  quotas: [
    [service: :azure_blob, limit: 1000, unit: :call, window: :minute, scope: :local],
    [service: :azure_blob, limit: 10_000_000, unit: :byte, window: :day, scope: :local],
    [service: :azure_blob, limit: 1_000_000_000, unit: :byte, window: :day, scope: :global]
  ]
```

## Release instructions

1. Create a Docker image

```sh
$ cd core
$ docker build  --build-arg VERSION=1.0.0 --build-arg BUNDLE=self . -t self:latest
$ docker image save self -o self.zip
```

2. Run the Docker image

Required environment variables:

| Variable | Description | Example value |
|---|---|---|
| APP_NAME | Core app name | "Self" |
| APP_DOMAIN | domain where the Core app is hosted | "my.server.com" |
| APP_MAIL_DOMAIN | Domain of your email (after the @) | "self.com" |
| APP_ADMINS | String with space seperated email adresses of the system admins, supports wildcards | "person1@self.com person2@self.com" |
| DB_USER | Username | \<my-username\> |
| DB_PASS | Password | \<my-password\> |
| DB_HOST | Hostname | "domain.where.database.lives" |
| DB_NAME | Name of the database in the PostgreSQL| "self_prod" |
| SECRET_KEY_BASE | 64-bit sequence of random characters | \<long-sequence-of-characters\> |
| STATIC_PATH | Path to folder where uploaded files can be stored | "/tmp" |
| UNSPLASH_ACCESS_KEY | Application access key registered on [Unsplash](https://unsplash.com/) (Image Catalog) | "hcejpnHRuFWL-fKXLYqhGBt1Dz0_tTjeNifgD01VkGE" |
| UNSPLASH_APP_NAME | Application name registered on [Unsplash](https://unsplash.com/) (Image Catalog) | "Self" |
| STORAGE_SERVICES | Comma seperated list of storage services | "yoda, aws, azure" |

Optional environment variables:

| Variable | Description | Example value |
|---|---|---|
| LOG_LEVEL | Console log level  | "debug", "info", "warn", "error" |
| SENTRY_DSN | app monitoring | https://1234febac1234365cfe2d1fad616845b@o1234721120555008.ingest.sentry.io/1235721234883520"
| GOOGLE_SIGN_IN_CLIENT_ID | | "123466465353-mui7en8912341rpn6qaevb89rd01234.apps.googleusercontent.com" |
| GOOGLE_SIGN_IN_CLIENT_SECRET | | "Q_lSWMy1234nPhxof1234Xyc" |
| SURFCONEXT_SITE | SURFconext site | "https://connect.test.surfconext.nl" |
| SURFCONEXT_CLIENT_ID | SURFconext client ID | "self.com" |
| SURFCONEXT_CLIENT_SECRET | SURFconext client secret | "12343HieOjb1234hcBpL" |
| STORAGE_S3_PREFIX | Prefix for S3 builtin storage objects. Without this variable "builtin" storage service will default to local filesystem | "storage" |
| CONTENT_S3_PREFIX | Prefix for S3 content objects | "content" |
| FELDSPAR_S3_PREFIX | Prefix for S3 feldspar objects | "feldspar" |
| PUBLIC_S3_URL | Public accessable url of an S3 service | "https://self-public.s3.eu-central-1.amazonaws.com" |
| PUBLIC_S3_BUCKET | Name of the bucket on the S3 service | "self-prod" |
| DIST_HOSTS | Comma seperated list of hosts in the cluster, see: [OTP Distribution](https://elixirschool.com/en/lessons/advanced/otp_distribution) | "one, two" |
