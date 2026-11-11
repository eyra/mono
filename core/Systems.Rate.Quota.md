# `Systems.Rate.Quota`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/rate/quota.ex#L1)

# `t`

```elixir
@type t() :: %Systems.Rate.Quota{
  limit: integer(),
  scope: :local | :global,
  service: String.t(),
  unit: :byte | :call,
  window: :day | :hour | :minute | :second
}
```

# `init`

# `merge`

Replaces the default quotas of every service that has an override; the other
services keep their defaults.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
