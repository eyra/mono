# `Systems.Payment.ReconciliationState`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/payment/reconciliation_state.ex#L1)

Accumulator threaded through a reconciliation sweep. Carries the running
`ReconciliationSummary` tally, the list of non-trivial findings to persist,
and the provider circuit-breaker state (consecutive failures → open).

# `add_finding`

# `circuit_open?`

# `new`

# `record_failure`

# `record_success`

# `tally`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
