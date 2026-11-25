# `Systems.BFF.Blocks.Search`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/bff/blocks.ex#L0)

Block `search`.

# `t`

```elixir
@type t() :: %Systems.BFF.Blocks.Search{
  id: String.t(),
  name: String.t(),
  placeholder: String.t() | nil,
  to: String.t(),
  value: String.t() | nil
}
```

# `to_map`

```elixir
@spec to_map(t()) :: map()
```

The wire shape, ready for any JSON encoder.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
