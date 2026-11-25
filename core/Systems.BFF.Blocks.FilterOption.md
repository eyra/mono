# `Systems.BFF.Blocks.FilterOption`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/bff/blocks.ex#L0)

Type `filter_option`.

# `t`

```elixir
@type t() :: %Systems.BFF.Blocks.FilterOption{
  label: String.t(),
  selected: boolean() | nil,
  to: String.t()
}
```

# `to_map`

```elixir
@spec to_map(t()) :: map()
```

The wire shape, ready for any JSON encoder.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
