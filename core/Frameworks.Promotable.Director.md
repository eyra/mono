# `Frameworks.Promotable.Director`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/concept/promotable_director.ex#L1)

# `error`

```elixir
@type error() :: atom()
```

# `promotable`

```elixir
@type promotable() :: map()
```

# `user`

```elixir
@type user() :: map()
```

# `reward_value`

```elixir
@callback reward_value(promotable()) :: integer()
```

# `validate_open`

```elixir
@callback validate_open(promotable(), user()) :: :ok | {:error, error()}
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
