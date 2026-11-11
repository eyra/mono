# `Systems.Admin.Panel`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/admin/panel.ex#L1)

A tab on the Admin page (`/admin/config`), with an embedded live view.

Systems contribute panels with `c:Mica.System.admin_panels/0`; the page shows
them in `c:Mica.SaaS.systems/0` order.

    defmodule Systems.Admin.ActionsPanel do
      use Systems.Admin.Panel
      use Gettext, backend: MicaWeb.Gettext

      @impl true
      def id, do: :actions

      @impl true
      def title, do: dgettext("eyra-admin", "actions.title")

      @impl true
      def audience, do: :admin

      @impl true
      def live_view, do: Systems.Admin.ActionsView
    end

The audience says who sees the panel: `:admin` only system admins,
`:org_admin` also admins of an organisation. System admins see every panel.
A panel that is not `c:enabled?/0`, for example because its feature flag is
off, is shown to nobody.

# `audience`

```elixir
@type audience() :: :admin | :org_admin
```

# `live_context`

```elixir
@type live_context() :: %Frameworks.Concept.LiveContext{data: map()}
```

# `viewer`

```elixir
@type viewer() :: :admin | :org_admin
```

# `audience`

```elixir
@callback audience() :: audience()
```

# `enabled?`

```elixir
@callback enabled?() :: boolean()
```

Whether the panel is on. Defaults to `true`.

# `id`

```elixir
@callback id() :: atom()
```

The tab id. The live view's element id is `admin_<id>_view`.

# `live_context`

```elixir
@callback live_context(live_context()) :: live_context()
```

The live context of the live view: the page's context (`current_user`,
`locale`, `is_admin?`, `governable_orgs`), extended with what the view needs.

# `live_view`

```elixir
@callback live_view() :: module()
```

The live view embedded in the tab.

# `title`

```elixir
@callback title() :: String.t()
```

# `in_audience?`

```elixir
@spec in_audience?(module(), viewer()) :: boolean()
```

Whether `viewer` is in the audience of `panel`, whether or not it is enabled.

# `shown_to?`

```elixir
@spec shown_to?(module(), viewer()) :: boolean()
```

Whether `viewer` sees `panel`.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
