# `Next.Systems.Annotation.Model`
[🔗](https://github.com/eyra/mono/blob/main/next/systems/annotation/model.ex#L1)

# `t`

```elixir
@type t() :: %Next.Systems.Annotation.Model{
  __meta__: Ecto.Schema.Metadata.t(),
  entity: term(),
  entity_id: integer() | nil,
  id: integer() | nil,
  inserted_at: NaiveDateTime.t(),
  references: term(),
  statement: String.t(),
  type: term(),
  type_id: integer() | nil,
  updated_at: NaiveDateTime.t()
}
```

# `changeset`

# `preload_graph`

# `validate`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
