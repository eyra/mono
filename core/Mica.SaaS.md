# `Mica.SaaS`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica/saas.ex#L1)

A SaaS built on Mica, and the composition of the configured one.

Each SaaS has one module that implements this behaviour (`Next.SaaS`,
`MicaSaas.SaaS`). It lists the systems the SaaS is made of and carries the
SaaS-level config. The build picks one in its config:

    config :mica, saas: Next.SaaS

The value is read at compile time: the router and `Mica.Authorization` splice
the routes and grants of all systems (`override_routes/0`, `routes/0`,
`grants/0`). Never set `:saas` in `runtime.exs`; a release refuses to boot
when it differs from the compiled value.

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

# `bff_pages`

The BFF pages of all systems. Raises when two systems serve the same page.

# `children`

The children of all systems, in `systems/0` order.

# `desktop_sections`

The Desktop sections of all systems, in `systems/0` order. Raises when two sections have the same id.

# `feature_flags`

The declared feature flags of all systems, off unless the SaaS turns them on,
sorted by name. Raises when the SaaS sets a flag that no system declares.

# `grants`
*macro* 

Expands to `grant_access/2` or `grant_actions/2` for every system grant.

# `migrations_paths`

The Ecto migration paths to run: Mica's own, then those of the systems that
have their own, in `systems/0` order.

# `module`

The configured SaaS module.

# `notifiers`

The notifiers of all systems, in `systems/0` order.

# `notify_channel_names`
*macro* 

The channel names of `notify_channels/0`, sorted, for use at compile time (an
`Ecto.Enum`). Editing a system recompiles the caller. Like the route and grant
macros, it compiles the SaaS module and its systems first, so they must not
depend on the caller at compile time.

# `notify_channels`

The notification channels of all systems. Raises when two systems name the same channel.

# `oban_crons`

The Oban crons of all systems, in `systems/0` order. Raises when two systems declare the same name.

# `oban_queues`

The Oban queues of all systems. Raises when two systems declare the same queue.

# `override_routes`
*macro* 

Splices `override_routes/0` of all systems.

# `rate_quotas`

The default rate quotas of all systems, in `systems/0` order.

# `routes`
*macro* 

Splices `routes/0` of all systems, in `systems/0` order.

# `sign_in_handoffs`

The sign-in handoffs of all systems, in `systems/0` order.

# `signal_handlers`

The signal handlers of all systems, sorted by module name within the system
namespaces: a SaaS system's handler (`Next.Systems.<System>.Switch`) sorts as
`Systems.<System>.Switch`, among Mica's.

# `systems`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
