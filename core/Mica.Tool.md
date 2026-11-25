# `Mica.Tool`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica/tool.ex#L1)

A tool type: what a workflow item can hold. One module per type, listed by its
system's `c:Mica.System.tools/0`:

    defmodule Systems.Feldspar.Tool do
      use Mica.Tool

      def type, do: "feldspar"
      def schema, do: Systems.Feldspar.ToolModel
      def prepare(attrs, %{auth_node: auth_node}), do: Systems.Feldspar.Public.prepare_tool(attrs, auth_node)
      def view, do: Systems.Feldspar.ToolView
    end

The type name is stored with every reference to a tool (`tool_refs.tool_type`),
so it never changes and never follows a module rename. It is unique in the
composition, and `"none"` is reserved: it marks a reference to no tool.

Behaviour of a loaded tool (labels, `ready?`, forms) stays in the
`Frameworks.Concept.ToolModel` protocol, whose `key/1` equals `type/0`.

# `context`

```elixir
@type context() :: %{
  :auth_node =&gt; struct(),
  optional(:user) =&gt; struct() | nil,
  optional(:director) =&gt; atom() | nil
}
```

What `prepare/2` gets besides the attributes.

# `prepare`

```elixir
@callback prepare(attrs :: map(), context()) :: Ecto.Changeset.t()
```

A changeset for a new tool of this type.

# `schema`

```elixir
@callback schema() :: module()
```

The tool's Ecto schema.

# `type`

```elixir
@callback type() :: String.t()
```

The stored type name, for example `"feldspar"`.

# `view`

```elixir
@callback view() :: module() | nil
```

The LiveView a participant works in, or `nil` when the tool has none.

# `reserved`

Type names no tool may use: `"none"` marks a reference to no tool.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
