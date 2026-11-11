# `Systems.Assignment.Template`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/assignment/template.ex#L1)

# `t`

```elixir
@type t() :: term()
```

All the types that implement this protocol.

# `tabs`

```elixir
@type tabs() :: [
  settings: {title(), Systems.Assignment.Template.Flags.Settings.t()} | nil,
  import: {title(), Systems.Assignment.Template.Flags.Import.t()} | nil,
  criteria: {title(), Systems.Assignment.Template.Flags.Criteria.t()} | nil,
  participants:
    {title(), Systems.Assignment.Template.Flags.Participants.t()} | nil,
  affiliate: {title(), Systems.Assignment.Template.Flags.Affiliate.t()} | nil,
  workflow: {title(), Systems.Assignment.Template.Flags.Workflow.t()} | nil,
  contributions:
    {title(), Systems.Assignment.Template.Flags.Contributions.t()} | nil,
  monitor: {binary(), Systems.Assignment.Template.Flags.Monitor.t()} | nil
]
```

# `title`

```elixir
@type title() :: binary()
```

# `currency`

```elixir
@spec currency(t()) :: atom()
```

# `runtime_config`

```elixir
@spec runtime_config(t()) :: Systems.Assignment.RuntimeConfig.t()
```

# `tabs`

```elixir
@spec tabs(t()) :: tabs()
```

# `title`

```elixir
@spec title(t()) :: binary()
```

# `workflow_config`

```elixir
@spec workflow_config(t()) :: Systems.Workflow.Config.t()
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
