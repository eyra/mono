# `Frameworks.Concept.PoolDirector`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/concept/pool_director.ex#L1)

# `currency`

```elixir
@type currency() :: binary()
```

# `error`

```elixir
@type error() :: map()
```

# `fund`

```elixir
@type fund() :: map()
```

# `plugin`

```elixir
@type plugin() :: %{module: atom(), params: map()}
```

# `submission`

```elixir
@type submission() :: map()
```

# `url_resolver`

```elixir
@type url_resolver() :: (atom(), list() -&gt; binary())
```

# `user`

```elixir
@type user() :: map()
```

# `inclusion_criteria`

```elixir
@callback inclusion_criteria() :: [atom()]
```

# `overview_plugin`

```elixir
@callback overview_plugin(user()) :: plugin() | nil
```

# `resolve_fund`

```elixir
@callback resolve_fund(currency(), user()) :: fund()
```

# `submission_plugin`

```elixir
@callback submission_plugin(user()) :: plugin() | nil
```

# `submit`

```elixir
@callback submit(submission_id :: integer()) :: {:ok, submission()} | {:error, error()}
@callback submit(submission_id :: integer()) :: {:ok, submission()} | {:error, error()}
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
