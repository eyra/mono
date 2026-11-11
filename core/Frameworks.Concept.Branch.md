# `Frameworks.Concept.Branch`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/concept/branch.ex#L1)

# `scope`

```elixir
@type scope() :: :self | :parent
```

# `t`

```elixir
@type t() :: term()
```

All the types that implement this protocol.

# `hierarchy`

```elixir
@spec hierarchy(t()) :: list()
```

# `name`

```elixir
@spec name(t(), scope()) :: binary()
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
