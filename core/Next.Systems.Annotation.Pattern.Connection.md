# `Next.Systems.Annotation.Pattern.Connection`
[🔗](https://github.com/eyra/mono/blob/main/next/systems/annotation/pattern/connection.ex#L1)

A pattern for creating a Connection Annotation.
A Connection is way to express that two annotations are related.

# `t`

```elixir
@type t() :: %Next.Systems.Annotation.Pattern.Connection{
  entity: Mica.Authentication.Entity.t() | nil,
  object: Next.Systems.Annotation.Model.t() | nil,
  statement: String.t() | nil,
  subject: Next.Systems.Annotation.Model.t() | nil
}
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
