# `Systems.Rate.Algorithm`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/rate/algorithm.ex#L1)

# `client_id`

```elixir
@type client_id() :: String.t()
```

# `packet_size`

```elixir
@type packet_size() :: integer()
```

# `permission_denied`

```elixir
@type permission_denied() :: {{:denied, :atom}, map()}
```

# `permission_granted`

```elixir
@type permission_granted() :: {:granted, map()}
```

# `permission_result`

```elixir
@type permission_result() :: permission_granted() | permission_denied()
```

# `service`

```elixir
@type service() :: :atom
```

# `state`

```elixir
@type state() :: map()
```

# `request_permission`

```elixir
@callback request_permission(state(), service(), client_id(), packet_size()) ::
  permission_result()
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
