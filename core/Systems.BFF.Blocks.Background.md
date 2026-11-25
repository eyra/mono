# `Systems.BFF.Blocks.Background`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/bff/blocks.ex#L0)

Markup `background`.

# `t`

```elixir
@type t() :: %Systems.BFF.Blocks.Background{
  color: String.t(),
  end: String.t(),
  start: String.t()
}
```

# `to_map`

```elixir
@spec to_map(t()) :: map()
```

The wire shape, ready for any JSON encoder.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
