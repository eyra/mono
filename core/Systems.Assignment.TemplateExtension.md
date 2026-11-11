# `Systems.Assignment.TemplateExtension`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/assignment/template_extension.ex#L1)

An assignment template that a SaaS adds next to the built-in
`Systems.Assignment.Templates`.

A SaaS registers its templates in config:

    config :mica, :assignment_templates, [MySaaS.SomeTemplate]

Each module defines the template struct (`defstruct [:id]`), implements
`Systems.Assignment.Template` for it and implements this behaviour.

# `enabled?`

```elixir
@callback enabled?() :: boolean()
```

Whether researchers can create new assignments from this template.

# `id`

```elixir
@callback id() :: atom()
```

The template id, stored as the assignment's `special`.

# `tool_description`

```elixir
@callback tool_description(special :: atom()) :: binary() | nil
```

Start screen description of a task with this workflow item special, or nil
to keep the tool's default.

# `all`

# `enabled`

# `get`

# `template!`

# `title`

# `tool_description`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
