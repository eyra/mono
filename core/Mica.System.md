# `Mica.System`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica/system.ex#L1)

The contract of one system: what it contributes to the SaaS it is part of.

Every system that contributes something has one `_system.ex`, next to its
`_routes.ex` and `_switch.ex`, defining `Systems.X.System` (or `Next.X.System`,
`MicaSaas.X.System` for a SaaS's own systems). A SaaS lists its systems in
`c:Mica.SaaS.systems/0`; `Mica.SaaS` collects their contributions.

    defmodule Systems.Pool.System do
      use Mica.System

      def routes do
        quote do
          require Systems.Pool.Routes
          Systems.Pool.Routes.routes()
        end
      end

      def grants do
        quote do
          [
            {Systems.Pool.LandingPage, [:visitor, :member, :owner]},
            {Systems.Pool.ContentPage, [:admin]}
          ]
        end
      end
    end

System modules are data modules and never call system code. The router and
`Mica.Authorization` read `override_routes/0`, `routes/0` and `grants/0` at
compile time, so these return quoted code. `grants/0` is quoted too: a module
name used as a value is a runtime dependency, and that would make the router
recompile whenever any granted page changes. The other callbacks return plain
values, which `Mica.SaaS` collects (`notify_channels/0` also at compile time,
for the `Systems.Notify.MessageModel` enum).

A SaaS extends Mica's systems only through its own systems, for example by
shadowing Mica's sign-in routes with `override_routes/0`.

Callbacks are only ever added with a default; removing or changing one breaks
the contract with every SaaS.

# `account_tabs`

```elixir
@callback account_tabs() :: [module()]
```

The system's `Systems.Account.Tab` modules: tabs on the account page, shown
after the tabs of earlier systems in `c:Mica.SaaS.systems/0`.

# `admin_panels`

```elixir
@callback admin_panels() :: [module()]
```

The system's `Systems.Admin.Panel` modules: tabs on the Admin page, shown
after the panels of earlier systems in `c:Mica.SaaS.systems/0`.

# `bff_pages`

```elixir
@callback bff_pages() :: %{required(atom()) =&gt; module()}
```

The BFF pages the system serves: page name to `Systems.BFF.Page` module, for
example `%{home: Systems.Home.BFFPage}`. The BFF serves a page only when the
mica-bff spec lists it (`Systems.BFF.Blocks.pages/0`).

# `children`

```elixir
@callback children() :: [Supervisor.child_spec() | {module(), term()} | module()]
```

Processes the system needs, started under `Mica.Supervisor` after
`Phoenix.PubSub` and before Oban, in `c:Mica.SaaS.systems/0` order.

# `desktop_sections`

```elixir
@callback desktop_sections() :: [module()]
```

The system's `Systems.Desktop.Section` modules: sections on the Desktop page,
before or after Recent items as each section's `placement/0` says, and after
the sections of earlier systems in `c:Mica.SaaS.systems/0` with the same
placement.

# `feature_flags`

```elixir
@callback feature_flags() :: [atom()]
```

The feature flags the system reads, as names. A declared flag is off unless
`c:Mica.SaaS.feature_flags/0` or the app config turns it on. Several systems
may declare the same flag.

# `grants`

```elixir
@callback grants() :: Macro.t()
```

Quoted list of page grants: `{module, roles}` for `grant_access/2`, or
`{module, %{action => roles}}` for `grant_actions/2`.

# `migrations_path`

```elixir
@callback migrations_path() :: Path.t() | nil
```

The absolute path of the system's own Ecto migrations, or `nil` when its
tables are in Mica's migrations. Migrated with Mica's, see
`Mica.SaaS.migrations_paths/0`.

# `notifiers`

```elixir
@callback notifiers() :: [module()]
```

The system's `Systems.Notify.EventDeclaration` modules (its `_notify.ex`).

# `notify_channels`

```elixir
@callback notify_channels() :: %{required(atom()) =&gt; module()}
```

The notification channels the system delivers: name to `Systems.Notify.Channel` module.

# `oban_crons`

```elixir
@callback oban_crons() ::
  keyword({String.t(), module()} | {String.t(), module(), keyword()})
```

The system's Oban cron jobs, by the name `ENABLED_OBAN_PLUGINS` enables them
with: `[advert_expiration: {"*/5 * * * *", Systems.Advert.ExpirationWorker}]`.
An entry is an `Oban.Plugins.Cron` crontab entry. A cron runs only where its
name is enabled (`Mica.ObanConfig`).

# `oban_queues`

```elixir
@callback oban_queues() :: keyword(pos_integer())
```

The Oban queues the system's workers use, with their limits: `[email_delivery: 1]`.

# `override_routes`

```elixir
@callback override_routes() :: Macro.t() | nil
```

Routes that must match before every other route, such as a SaaS's own sign-in
pages. Spliced at the top of `MicaWeb.Router`, in `c:Mica.SaaS.systems/0` order.

# `rate_quotas`

```elixir
@callback rate_quotas() :: [keyword()]
```

The default `Systems.Rate` quotas of the services the system limits, as keyword
lists: `[service: :signup, limit: 5, unit: :call, window: :minute, scope: :local]`.

# `routes`

```elixir
@callback routes() :: Macro.t() | nil
```

The system's routes, spliced inside `MicaWeb.Routes` in `c:Mica.SaaS.systems/0` order.

# `seeds`

```elixir
@callback seeds(deploy_env :: atom()) :: :ok
```

Seeds the records the system needs in the deploy environment (`:prod`,
`:staging`, `:dev`, `:test`, `:local`). `Mica.Seeds` runs it on every
deployment, after Mica's own seeds and in `c:Mica.SaaS.systems/0` order, so
it must be idempotent.

# `sign_in_handoffs`

```elixir
@callback sign_in_handoffs() :: [module()]
```

The system's `Systems.Account.SignInHandoff` modules. When an
identity-provider sign-in ends, the first one that takes it answers instead
of the site, in `c:Mica.SaaS.systems/0` order.

# `signal_handlers`

```elixir
@callback signal_handlers() :: [module()]
```

The system's `Frameworks.Signal.Handler` modules (its `_switch.ex`).
`c:Mica.SaaS.signal_handlers/0` dispatches to all of them, sorted by module name.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
