# `Frameworks.Concept.LiveHook`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/concept/live_hook.ex#L1)

# `live_view_module`

```elixir
@type live_view_module() :: atom()
```

# `params`

```elixir
@type params() :: map()
```

# `session`

```elixir
@type session() :: map()
```

# `socket`

```elixir
@type socket() :: Phoenix.LiveView.Socket.t()
```

# `mount`

```elixir
@callback mount(live_view_module(), params(), session(), socket()) ::
  {:cont | :halt, socket()}
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
