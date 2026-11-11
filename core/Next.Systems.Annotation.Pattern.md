# `Next.Systems.Annotation.Pattern`
[🔗](https://github.com/eyra/mono/blob/main/next/systems/annotation/pattern.ex#L1)

A protocol for creating Annotation Patterns.
Naming convention:
- Each pattern is named after the type of annotation it creates.
- Each pattern name is a noun, like "Definition", "Parameter", "Retraction", etc.

# `t`

```elixir
@type t() :: term()
```

All the types that implement this protocol.

# `obtain`

```elixir
@spec obtain(t()) ::
  {:ok, Next.Systems.Annotation.Model.t()} | {:error, {atom(), any()}}
```

  Obtain an annotation from a pattern. It returns an annotation and inserts it if it doesn't exist.

# `query`

```elixir
@spec query(t()) :: {:ok, Ecto.Query.t()} | {:error, {atom(), any()}}
```

  Query annotations based on a pattern. It returns a query that can be used to load annotations from the database.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
