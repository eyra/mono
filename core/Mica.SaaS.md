# `Mica.SaaS`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica/saas.ex#L1)

A SaaS built on Mica, and the composition of the configured one.

Each SaaS has one module that implements this behaviour (`Next.SaaS`,
`MicaSaas.SaaS`). It lists the systems the SaaS is made of and carries the
SaaS-level config. The build picks one in its config:

    config :mica, saas: Next.SaaS

Mica reads the value at runtime only. At boot `validate!/0` builds the
composition, the contributions of all systems, checks it and caches it; the
readers below (`signal_handlers/0`, `grants/0`, ...) take their part from
that cache. Each SaaS has its own router, which splices the routes of its
systems (`Mica.SaaS.Routes`), so no Mica module is compiled against the
configured SaaS. Set `:saas` only in the SaaS's config, not in `runtime.exs`:
the endpoint config of a build is the SaaS's.

# `endpoint`

```elixir
@callback endpoint() :: module()
```

The SaaS's endpoint, built with `use MicaWeb.Endpoint`.

# `feature_flags`
*optional* 

```elixir
@callback feature_flags() :: keyword(boolean())
```

The SaaS defaults of declared feature flags: `[password_sign_in: true]`. Every
name must be declared by one of its systems (`c:Mica.System.feature_flags/0`).

# `identify_page`

```elixir
@callback identify_page(:creator | :participant) :: String.t()
```

The page where a user enters an email address and is sent on to the way
they sign in (a one-time code or an identity provider), for a creator or a
participant. Mica appends a return path.

# `member_sign_in_page`

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

# `router`

```elixir
@callback router() :: module()
```

The SaaS's router, `use Phoenix.Router` with Mica's pipelines and routes
(`MicaWeb.Pipelines`, `Mica.SaaS.Routes`, `MicaWeb.BaseRoutes`). The endpoint
plugs it.

# `session_path`

```elixir
@callback session_path() :: String.t()
```

The path of the SaaS's session controller: the password sign-in form posts
to it, and signing out deletes it.

# `sign_in_options_page`

```elixir
@callback sign_in_options_page() :: String.t()
```

The page that offers every way the SaaS has to sign in (a password, identity
providers). Mica sends users there after they sign out, reset their password
or fail to sign in through a provider.

# `sign_in_page`

```elixir
@callback sign_in_page() :: String.t()
```

Where a signed-out user is sent to sign in. Mica has no sign-in pages of its
own: this callback and the four below name the SaaS's, and none has a default.

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

# `directors`

The directors of all systems as `{name, module}`, in `systems/0` order. Read through `Mica.Directors`.

# `endpoint`

The endpoint of the SaaS (`c:endpoint/0`). Mica reaches the endpoint only through this.

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

The configured SaaS module (`config :mica, saas:`). Raises in the composition
of Mica's own tests, which has no SaaS (`put_composition/1`), so every
callback reached through it raises there.

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

# `project_items`

The `Mica.ProjectItem` modules of all systems, in `systems/0` order. Read through `Mica.ProjectItems`.

# `put_composition`

Test hook: replaces parts of the composition for every process. Returns the
composition it replaced, to put back when the test ends:

    previous = Mica.SaaS.put_composition(signal_handlers: [MyTest.Switch])
    on_exit(fn -> Mica.SaaS.put_composition(previous) end)

The result is not checked, so a test can put a broken composition. A test
that calls it must not be `async`.

With no SaaS configured and no composition yet, `systems:` builds a
composition of those systems that is not a SaaS's: Mica's own tests run on
`put_composition(systems: Mica.Systems.all())`. It has no SaaS module, router
or endpoint: `module/0`, `endpoint/0` and `router/0` raise in it, and so does
every `Mica.SaaS` callback.

# `rate_quotas`

The default rate quotas of all systems, in `systems/0` order. Read once, at boot.

# `router`

The router of the SaaS (`c:router/0`), which its endpoint plugs.

# `saas?`

False in the composition of Mica's own tests, which has no SaaS module, router
or endpoint (`put_composition/1`); true otherwise.

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

# `tools`

The `Mica.Tool` modules of all systems, in `systems/0` order. Read through `Mica.Tools`.

# `validate!`

Builds the composition of the configured SaaS, checks it (`validate!/1`) and
caches it. `Mica.Application` runs it at boot, before the children start, so
a broken composition stops the boot. With no SaaS configured it checks the
composition of Mica's own tests instead, which their test helper puts before
the boot.

# `validate!`

The composition of `saas`, after checking it. Raises on:

  * a SaaS module that is no `Mica.SaaS`, or a system that is no `Mica.System`
  * an endpoint that is no `MicaWeb.Endpoint`, or a router that is no
    `Phoenix.Router`
  * a system, signal handler, notifier, sign-in handoff or assignment template
    listed twice, or an event type that two notifiers declare
  * a notify channel, Oban queue, Oban cron, Desktop section id or BFF page
    that two systems declare
  * a flag default that no system declares
  * a permission granted twice, unless the later grant says `widen: true`;
    each widening is logged
  * a notifier event routed to a channel that no system declares
  * a tool or project item type that is no `Mica.Tool` or `Mica.ProjectItem`,
    whose name two of them declare or is reserved (`"none"`), or whose schema
    two of them share; a tool whose `Frameworks.Concept.ToolModel.key/1` is not
    its type
  * a director name that two systems declare

---

*Consult [api-reference.md](api-reference.md) for complete listing*
