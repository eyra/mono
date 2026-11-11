# `Next.Systems.Annotation.Pattern.Relevance`
[🔗](https://github.com/eyra/mono/blob/main/next/systems/annotation/pattern/relevance.ex#L1)

A pattern for creating a Relevance Annotation.
A Relevance Annotation states the relevance between a parameter and a resource.

# `t`

```elixir
@type t() :: %Next.Systems.Annotation.Pattern.Relevance{
  entity: Mica.Authentication.Entity.t() | nil,
  parameter: Next.Systems.Annotation.Model.t() | nil,
  relevance: :relevant | :irrelevant | :neutral,
  resource: Next.Systems.Annotation.ResourceModel.t() | nil,
  superseded: term()
}
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
