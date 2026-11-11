# `Systems.Account.Tab`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/account/tab.ex#L1)

A tab on the account page (`Systems.Account.Page`): Profile, Payouts, Features, ….

Systems contribute tabs with `c:Mica.System.account_tabs/0`; the page shows
the visible ones in `c:Mica.SaaS.systems/0` order.

Each tab module must implement:
- key/0: Returns the unique key for this tab
- visible?/1: Determines if this tab should be visible for the given user
- build/2: Builds the tab data structure with a LiveNest element

# `live_context`

```elixir
@type live_context() :: %Frameworks.Concept.LiveContext{data: map()}
```

# `tab_spec`

```elixir
@type tab_spec() :: %{
  id: atom(),
  title: String.t(),
  type: atom(),
  element: LiveNest.Element.t(),
  ready?: boolean()
}
```

# `user`

```elixir
@type user() :: Systems.Account.User.t()
```

# `build`

```elixir
@callback build(user(), live_context()) :: tab_spec()
```

# `key`

```elixir
@callback key() :: atom()
```

# `visible?`

```elixir
@callback visible?(user()) :: boolean()
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
