# `Systems.BFF.Blocks.NextBestAction`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/bff/blocks.ex#L0)

Block `next_best_action`.

# `t`

```elixir
@type t() :: %Systems.BFF.Blocks.NextBestAction{
  body: String.t() | nil,
  cta: String.t() | nil,
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
