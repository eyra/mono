# `Systems.Workflow.Config`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/workflow/config.ex#L1)

# `item`

```elixir
@type item() :: atom()
```

# `library`

```elixir
@type library() :: Frameworks.Builder.LibraryModel.t()
```

# `t`

```elixir
@type t() :: %Systems.Workflow.Config{
  group_enabled?: boolean() | nil,
  initial_items: [item()],
  library: library(),
  singleton?: boolean()
}
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
