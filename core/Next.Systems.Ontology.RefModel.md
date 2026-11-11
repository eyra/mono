# `Next.Systems.Ontology.RefModel`
[🔗](https://github.com/eyra/mono/blob/main/next/systems/ontology/ref_model.ex#L1)

  A module referencing a model in the Ontology.

  One of the `term` or `predicate` must be present.

# `t`

```elixir
@type t() :: %Next.Systems.Ontology.RefModel{
  __meta__: Ecto.Schema.Metadata.t(),
  concept: term(),
  concept_id: integer() | nil,
  id: integer() | nil,
  inserted_at: NaiveDateTime.t(),
  predicate: term(),
  predicate_id: integer() | nil,
  updated_at: NaiveDateTime.t()
}
```

# `changeset`

# `get_target`

# `preload_graph`

# `validate`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
