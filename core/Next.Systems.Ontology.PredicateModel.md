# `Next.Systems.Ontology.PredicateModel`
[🔗](https://github.com/eyra/mono/blob/main/next/systems/ontology/predicate_model.ex#L1)

# `t`

```elixir
@type t() :: %Next.Systems.Ontology.PredicateModel{
  __meta__: Ecto.Schema.Metadata.t(),
  entity: term(),
  entity_id: integer() | nil,
  id: integer() | nil,
  inserted_at: NaiveDateTime.t(),
  object: term(),
  object_id: integer() | nil,
  subject: term(),
  subject_id: integer() | nil,
  type: term(),
  type_id: integer() | nil,
  type_negated?: boolean(),
  updated_at: NaiveDateTime.t()
}
```

# `changeset`

# `preload_graph`

# `validate`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
