# `Systems.Payment.Reconciliation`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/payment/reconciliation.ex#L1)

Support for the reconciliation sweep: provider calls wrapped with throttling,
back-off and a circuit breaker, plus the run/finding persistence lifecycle.

The per-type reconcilers (`Fund.PayoutReconciliation`,
`Fund.TransactionReconciliation`) thread a `ReconciliationState` through their
rows and reach the provider only via `get_withdrawal/2` and `get_transaction/2`
here, so rate-limit and outage handling lives in one place.

# `finish_run`

Persists the accumulated findings and finalizes the run row with its tally.

# `get_transaction`

# `get_withdrawal`

Provider withdrawal lookup guarded by the circuit breaker, throttle and
back-off. Returns `{result, state}` where `result` is the provider tuple or
`:circuit_open` when the breaker tripped earlier in the run.

# `list_recent_merchants`

# `list_recent_transactions`

# `list_recent_transfers`

# `list_recent_withdrawals`

Provider-side listings for the provider→local pass, under the same breaker and
throttle as the per-row lookups. One call covers a whole sweep, so a tripped
breaker here skips the entire pass rather than a single row.

# `new_state`

# `scan_window`

Creation window a provider→local scan considers, as `{oldest, newest}`.

`oldest` bounds how far back the provider listing reaches. `newest` is a
min-age guard: an object created moments ago may have a local row committing
right now, and flagging it would flap.

Overridable per run via `:min_age_minutes` and `:max_age_days`, matching the
options the local-first reconcilers take.

# `start_run`

Inserts a run row at the start of a sweep.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
