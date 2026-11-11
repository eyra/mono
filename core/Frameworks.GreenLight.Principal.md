# `Frameworks.GreenLight.Principal`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/green_light/principal.ex#L1)

The principal is used as a representation for any person / thing that can
interact with the system.

For more information see the [Wikipedia article on
principals](https://en.wikipedia.org/wiki/Principal_(computer_security)/).

# `t`

```elixir
@type t() :: term()
```

All the types that implement this protocol.

# `id`

```elixir
@spec id(t()) :: integer() | nil
```

# `roles`

```elixir
@spec roles(t()) :: MapSet.t(atom())
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
