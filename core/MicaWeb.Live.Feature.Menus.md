# `MicaWeb.Live.Feature.Menus`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/live/feature/menus.ex#L1)

# `active_menu_item`

```elixir
@type active_menu_item() :: atom()
```

# `menu_builder`

```elixir
@type menu_builder() :: atom()
```

# `menus`

```elixir
@type menus() :: [atom()]
```

# `get_menus_config`

```elixir
@callback get_menus_config() ::
  {menu_builder(), menus()}
  | {menu_builder(), menus(), active_menu_item()}
  | nil
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
