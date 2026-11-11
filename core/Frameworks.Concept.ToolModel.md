# `Frameworks.Concept.ToolModel`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/concept/tool_model.ex#L1)

# `t`

```elixir
@type t() :: term()
```

All the types that implement this protocol.

# `apply_label`

```elixir
@spec apply_label(t()) :: binary()
```

# `attention_list_enabled?`

```elixir
@spec attention_list_enabled?(t()) :: boolean()
```

# `auth_tree`

```elixir
@spec auth_tree(t()) :: tuple() | list() | struct() | nil
```

# `form`

```elixir
@spec form(t(), special :: atom()) :: atom()
```

# `group_enabled?`

```elixir
@spec group_enabled?(t()) :: boolean()
```

# `key`

```elixir
@spec key(t()) :: atom()
```

# `open_label`

```elixir
@spec open_label(t()) :: binary()
```

# `ready?`

```elixir
@spec ready?(t()) :: boolean()
```

# `task_labels`

```elixir
@spec task_labels(t()) :: map()
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
