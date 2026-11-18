# `Systems.BFF.Blocks.Participation`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/bff/blocks.ex#L0)

Block `participation`.

# `t`

```elixir
@type t() :: %Systems.BFF.Blocks.Participation{
  reward: String.t() | nil,
  status_label: String.t() | nil,
  status_tone: (:accent | :success | :warning | :danger | :neutral) | nil,
  subtitle: String.t() | nil,
  title: String.t(),
  to: String.t() | nil
}
```

# `to_map`

```elixir
@spec to_map(t()) :: map()
```

The wire shape, ready for any JSON encoder.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
