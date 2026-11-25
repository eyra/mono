# `Mica.ProjectItem`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica/project_item.ex#L1)

A project item type: what a project item can hold. One module per type, listed
by its system's `c:Mica.System.project_items/0`:

    defmodule Systems.Assignment.ProjectItem do
      use Mica.ProjectItem

      def type, do: "assignment"
      def schema, do: Systems.Assignment.Model
    end

The type name is stored with every project item (`project_items.item_type`), so
it never changes. It is unique in the composition, and `"none"` is reserved: it
marks an item that holds nothing.

Behaviour of a loaded target (tag, status, info) stays in the
`Frameworks.Concept.Leaf` protocol.

# `schema`

```elixir
@callback schema() :: module()
```

The target's Ecto schema.

# `type`

```elixir
@callback type() :: String.t()
```

The stored type name, for example `"assignment"`.

# `reserved`

Type names no item type may use: `"none"` marks an item that holds nothing.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
