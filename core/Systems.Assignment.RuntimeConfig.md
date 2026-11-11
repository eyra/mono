# `Systems.Assignment.RuntimeConfig`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/assignment/runtime_config.ex#L1)

Configuration for participant-facing runtime behavior of an assignment.

Returned by `Assignment.Template.runtime_config/1` and consumed by the
parts of the system that need to know which pool a template targets —
today: the finished view (post-completion email capture) and the
participants view (advert-in-pool CTA).

## Fields

  * `:pool` — atom slug of the pool this template targets, e.g. `:panl`.
    `nil` means the template is not pool-scoped.

# `t`

```elixir
@type t() :: %Systems.Assignment.RuntimeConfig{pool: atom() | nil}
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
