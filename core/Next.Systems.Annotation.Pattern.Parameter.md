# `Next.Systems.Annotation.Pattern.Parameter`
[🔗](https://github.com/eyra/mono/blob/main/next/systems/annotation/pattern/parameter.ex#L1)

A pattern for creating a Parameter Annotation.

A Parameter is a quantifiable or descriptive characteristic, value, or condition that specifies
or defines a particular aspect of a Dimension within a scientific system, process, model, or
phenomenon under investigation. Parameters serve as inputs, constants, or variables that
characterize or influence a Dimension, enabling the description, measurement, manipulation, or
control of relationships, behaviors, or outcomes in a scientific study.

# `t`

```elixir
@type t() :: %Next.Systems.Annotation.Pattern.Parameter{
  dimension: Next.Systems.Ontology.ConceptModel.t() | nil,
  entity: Mica.Authentication.Entity.t() | nil,
  statement: String.t() | nil
}
```

# `type_phrase`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
