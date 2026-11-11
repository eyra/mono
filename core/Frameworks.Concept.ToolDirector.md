# `Frameworks.Concept.ToolDirector`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/concept/tool_director.ex#L1)

# `authorization_context`

```elixir
@type authorization_context() :: nil | struct()
```

# `member`

```elixir
@type member() :: map()
```

# `public_id`

```elixir
@type public_id() :: binary()
```

# `subject`

```elixir
@type subject() :: {member(), [task()]}
```

# `task`

```elixir
@type task() :: map()
```

# `tool`

```elixir
@type tool() :: map()
```

# `user`

```elixir
@type user() :: map()
```

# `user_ref`

```elixir
@type user_ref() :: user() | public_id()
```

# `assign_tester_role`

```elixir
@callback assign_tester_role(tool(), user()) :: :ok | :error
```

# `authorization_context`

```elixir
@callback authorization_context(tool(), user()) :: authorization_context()
```

# `search_subject`

```elixir
@callback search_subject(tool(), user_ref()) :: subject() | nil
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
