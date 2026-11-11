# `Systems.Rate.LeakyBucketState`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/rate/leaky_bucket_state.ex#L1)

# `t`

```elixir
@type t() :: %Systems.Rate.LeakyBucketState{
  buckets: %{required(String.t()) =&gt; Systems.Rate.LeakyBucket.t()},
  prune_interval: integer(),
  quotas: [Systems.Rate.Quota.t()]
}
```

# `init`

# `prune`

# `update`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
