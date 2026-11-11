# `MicaWeb.Menu.Builder`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/live/menu/builder.ex#L1)

# `active_item`

```elixir
@type active_item() :: atom()
```

# `item`

```elixir
@type item() :: atom()
```

# `menu`

```elixir
@type menu() :: map()
```

# `socket`

```elixir
@type socket() :: map()
```

# `type`

```elixir
@type type() :: atom()
```

# `uri`

```elixir
@type uri() :: binary() | nil
```

# `user`

```elixir
@type user() :: map() | nil
```

# `build_menu`

```elixir
@callback build_menu(type(), active_item(), user(), uri()) :: menu()
```

# `include_map`

```elixir
@callback include_map(user()) :: map()
```

# `include_map`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
