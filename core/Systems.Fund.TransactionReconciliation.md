# `Systems.Fund.TransactionReconciliation`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/fund/transaction_reconciliation.ex#L1)

Reconciliation for pay-in transactions. Re-applies the provider's current
status to `:pending`/`:failed` transactions whose webhook was lost (including
rescuing one the expiry worker marked `:failed` while the provider actually
completed it), and flags `:completed` transactions the provider has no record
of — a critical discrepancy. Driven by `Systems.Payment.ReconciliationWorker`;
provider calls go through `Systems.Payment.Reconciliation`
(throttle / back-off / circuit breaker) and the shared `ReconciliationState`
is threaded through and returned.

# `run`

Reconciles `:pending`, `:failed` and `:completed` transactions in the
`[min_age_minutes, max_age_days]` window, returning the updated state.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
