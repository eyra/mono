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
