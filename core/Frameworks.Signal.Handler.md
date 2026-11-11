# `Frameworks.Signal.Handler`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/signal/handler.ex#L1)

# `message`

```elixir
@type message() :: any()
```

# `result`

```elixir
@type result() :: :ok | {:error, atom()} | {:continue, atom(), any()}
```

# `signal`

```elixir
@type signal() :: atom() | map() | {:atom, signal()}
```

# `intercept`

```elixir
@callback intercept(signal(), message()) :: result()
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
