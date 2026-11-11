# `Systems.BFF.Blocks`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/bff/blocks/_spec.ex#L2)

The BFF spec's pages: each is a GET at its path that returns a flat list of blocks.

# `pages`

```elixir
@spec pages() :: [%{name: atom(), path: String.t()}]
```

The pages the BFF serves, in spec order.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
