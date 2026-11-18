# `Mica.SaaS`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica/saas.ex#L1)

A SaaS built on Mica, and the composition of the configured one.

Each SaaS has one module that implements this behaviour (`Next.SaaS`,
`MicaSaas.SaaS`). It lists the systems the SaaS is made of and carries the
SaaS-level config. The build picks one in its config:

    config :mica, saas: Next.SaaS

Mica reads the value at runtime. At boot `validate!/0` builds the
composition, the contributions of all systems, checks it and caches it; the
readers below (`signal_handlers/0`, `grants/0`, ...) take their part from
that cache. Only `MicaWeb.Router` still reads the value at compile time, to
splice the routes of all systems (`override_routes/0`, `routes/0`). Never set
`:saas` in `runtime.exs`; a release refuses to boot when it differs from the
value the router was compiled with.

# `feature_flags`
*optional* 

```elixir
@callback feature_flags() :: keyword(boolean())
```

The SaaS defaults of declared feature flags: `[password_sign_in: true]`. Every
name must be declared by one of its systems (`c:Mica.System.feature_flags/0`).

# `member_sign_in_page`
*optional* 

```elixir
@callback member_sign_in_page(return_to :: String.t()) :: String.t()
```

Where a signed-out user is sent to sign in for a page participants open, which they return to.

# `menu_builder`

```elixir
@callback menu_builder(:workspace | :website | :stripped) :: module()
```

The menu builder for a layout.

# `menu_items`

```elixir
@callback menu_items() :: module()
```

The `MicaWeb.Menu.ItemsProvider` implementation.

# `sign_in_page`
*optional* 

```elixir
@callback sign_in_page() :: String.t()
```

Where a signed-out user is sent to sign in.

# `sign_up_page`
*optional* 

```elixir
@callback sign_up_page(
  user_type :: :creator | :participant,
  post_signup_action :: String.t() | nil
) ::
  String.t() | nil
```

Where a signed-out user is sent to sign up instead of the password sign-up
page (`/user/signup/:user_type`), or nil to keep that page. The page's
`post_signup_action` param is passed along, nil when it has none.

# `signed_in_page`

```elixir
@callback signed_in_page(:creator | :member) :: String.t()
```

Where a user lands after signing in, unless a return path is set.

# `start_pages`

```elixir
@callback start_pages() :: module()
```

The `MicaWeb.StartPageProvider` implementation.

# `systems`

```elixir
@callback systems() :: [module()]
```

The systems the SaaS is made of: `Mica.Systems.all() ++` its own systems.

# `title`
*optional* 

```elixir
@callback title() :: String.t()
```

The product name shown in page titles.

# `account_tabs`

The account tabs of all systems, in `systems/0` order.

# `admin_panels`

The admin panels of all systems, in `systems/0` order.

# `assignment_templates`

The assignment templates of all systems, in `systems/0` order.

# `bff_pages`

The BFF pages of all systems.

# `children`

The children of all systems, in `systems/0` order. Read once, at boot.

# `desktop_sections`

The Desktop sections of all systems, in `systems/0` order.

# `feature_flags`

The declared feature flags of all systems, off unless the SaaS turns them on,
sorted by name.

# `grants`

The page grants of all systems, in `systems/0` order: `{module, roles}` or
`{module, %{action => roles}}`, with `widen: true` as a third element when
the grant widens another one. `Mica.Authorization` merges them into its
permission map at boot.

# `migrations_paths`

The Ecto migration paths to run: Mica's own, then those of the systems that
have their own, in `systems/0` order.

# `module`

The configured SaaS module (`config :mica, saas:`).

# `notifiers`

The notifiers of all systems, in `systems/0` order.

# `notify_channels`

The notification channels of all systems.

# `notify_events`

The notify event types of all notifiers, to the channels each is routed to: `%{"type" => [:email]}`.

# `oban_crons`

The Oban crons of all systems, in `systems/0` order. Read once, at boot.

# `oban_queues`

The Oban queues of all systems. Read once, at boot.

# `override_routes`
*macro* 

Splices `override_routes/0` of all systems, and records their paths for
`MicaWeb.PathCheck` (a SaaS's own pages that shadow Mica's).

# `put_composition`

Test hook: replaces parts of the composition for every process. Returns the
composition it replaced, to put back when the test ends:

    previous = Mica.SaaS.put_composition(signal_handlers: [MyTest.Switch])
    on_exit(fn -> Mica.SaaS.put_composition(previous) end)

The result is not checked, so a test can put a broken composition. A test
that calls it must not be `async`.

# `rate_quotas`

The default rate quotas of all systems, in `systems/0` order. Read once, at boot.

# `routes`
*macro* 

Splices `routes/0` of all systems, in `systems/0` order.

# `schemas`

The Ecto schemas of every application in the composition: Mica's and those of
the applications that hold the SaaS module or one of its systems.
`Mica.Repo.orphan?/2` and `Mica.Authorization` scan them.

The list comes from the applications, not from a callback per system, so a
system can't leave one of its schemas out. A schema in an application that
holds neither the SaaS module nor any of its systems is not in it.

# `sign_in_handoffs`

The sign-in handoffs of all systems, in `systems/0` order.

# `signal_handlers`

The signal handlers of all systems, sorted by module name within the system
namespaces: a SaaS system's handler (`Next.Systems.<System>.Switch`) sorts as
`Systems.<System>.Switch`, among Mica's.

# `systems`

The systems the SaaS is made of, in `c:systems/0` order.

# `validate!`

Builds the composition of the configured SaaS, checks it (`validate!/1`) and
caches it. `Mica.Application` runs it at boot, before the children start, so
a broken composition stops the boot.

# `validate!`

The composition of `saas`, after checking it. Raises on:

  * a SaaS module that is no `Mica.SaaS`, or a system that is no `Mica.System`
  * a system, signal handler, notifier, sign-in handoff or assignment template
    listed twice, or an event type that two notifiers declare
  * a notify channel, Oban queue, Oban cron, Desktop section id or BFF page
    that two systems declare
  * a flag default that no system declares
  * a permission granted twice, unless the later grant says `widen: true`;
    each widening is logged
  * a notifier event routed to a channel that no system declares

---

*Consult [api-reference.md](api-reference.md) for complete listing*
