# `Systems.BFF.Blocks.Section`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/bff/blocks/section.ex#L2)

Block `section`.

# `t`

```elixir
@type t() :: %Systems.BFF.Blocks.Section{
  body: String.t() | nil,
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
