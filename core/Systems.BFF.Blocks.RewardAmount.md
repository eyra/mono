# `Systems.BFF.Blocks.RewardAmount`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/bff/blocks.ex#L0)

Block `reward_amount`.

# `t`

```elixir
@type t() :: %Systems.BFF.Blocks.RewardAmount{
  amount: String.t(),
  caption: String.t() | nil,
  label: String.t(),
  tone: (:accent | :success | :warning | :danger | :neutral) | nil
}
```

# `to_map`

```elixir
@spec to_map(t()) :: map()
```

The wire shape, ready for any JSON encoder.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
