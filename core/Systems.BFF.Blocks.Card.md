# `Systems.BFF.Blocks.Card`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/bff/blocks/card.ex#L2)

Block `card`.

# `t`

```elixir
@type t() :: %Systems.BFF.Blocks.Card{
  body: String.t() | nil,
  cta: String.t() | nil,
  title: String.t() | nil,
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
