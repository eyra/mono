# `Systems.BFF.Blocks.SectionBegin`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/bff/blocks.ex#L0)

Block `section_begin`.

# `t`

```elixir
@type t() :: %Systems.BFF.Blocks.SectionBegin{
  background: String.t() | nil,
  border: boolean() | nil
}
```

# `to_map`

```elixir
@spec to_map(t()) :: map()
```

The wire shape, ready for any JSON encoder.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
