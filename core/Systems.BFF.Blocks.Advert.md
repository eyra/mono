# `Systems.BFF.Blocks.Advert`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/bff/blocks.ex#L0)

Block `advert`.

# `t`

```elixir
@type t() :: %Systems.BFF.Blocks.Advert{
  image_url: String.t() | nil,
  info: String.t() | nil,
  logo_url: String.t() | nil,
  tags: [String.t()] | nil,
  title: String.t(),
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
