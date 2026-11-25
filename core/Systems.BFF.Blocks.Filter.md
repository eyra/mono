# `Systems.BFF.Blocks.Filter`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/bff/blocks.ex#L0)

Block `filter`.

# `t`

```elixir
@type t() :: %Systems.BFF.Blocks.Filter{
  id: String.t(),
  label: String.t() | nil,
  options: [Systems.BFF.Blocks.FilterOption.t()]
}
```

# `to_map`

```elixir
@spec to_map(t()) :: map()
```

The wire shape, ready for any JSON encoder.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
