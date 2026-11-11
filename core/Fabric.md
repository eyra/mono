# `Fabric`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/fabric.ex#L1)

# `assigns`

```elixir
@type assigns() :: map()
```

# `child`

```elixir
@type child() :: %{module: module(), params: map()}
```

# `composition`

```elixir
@type composition() :: child() | element()
```

# `composition_id`

```elixir
@type composition_id() :: atom() | binary()
```

# `element`

```elixir
@type element() :: map() | binary() | number()
```

# `socket`

```elixir
@type socket() :: Phoenix.LiveView.Socket.t()
```

# `compose`

```elixir
@callback compose(id :: composition_id(), a :: assigns()) :: composition() | nil
```

# `handle_modal_closed`
*optional* 

```elixir
@callback handle_modal_closed(socket(), any()) :: socket()
```

# `add_child`

# `child_id`

# `compose_child`

# `exists?`

# `get_child`

# `get_current_child`

# `hide_child`

# `install_children`

# `new_fabric`

# `new_fabric`

# `prepare_child`

# `prepare_child`

# `remove_child`

# `replace_child`

# `reset_children`

# `send_event`

# `send_event`

# `show_child`

# `show_next`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
