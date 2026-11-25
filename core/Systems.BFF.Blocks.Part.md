# `Systems.BFF.Blocks.Part`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/bff/blocks.ex#L0)

Markup `part`.

# `t`

```elixir
@type t() :: %Systems.BFF.Blocks.Part{
  end: String.t(),
  role: :main | :related,
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
