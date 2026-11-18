# `Systems.BFF.Blocks`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/bff/blocks.ex#L1)

The BFF blocks and pages, generated at compile time from the mica-bff spec.

# `pages`

```elixir
@spec pages() :: [%{name: atom(), path: String.t()}]
```

The pages the BFF serves, in spec order: each is a GET at its path that returns a flat list of blocks.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
