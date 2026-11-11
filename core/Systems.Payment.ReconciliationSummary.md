# `Systems.Payment.ReconciliationSummary`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/payment/reconciliation_summary.ex#L1)

Tally of a reconciliation run, shared by the per-type reconcilers
(`Fund.Public.reconcile_pending_payouts/1`, `Fund.Public.reconcile_transactions/1`)
and aggregated by `Systems.Payment.ReconciliationWorker`.

Outcomes:
  * `:resolved_completed`  — provider terminal "completed"; local driven to completed.
  * `:resolved_failed`     — provider terminal failure; local driven to failed.
  * `:still_pending`       — provider still in flight; left untouched.
  * `:verified`            — local terminal state confirmed present at the provider.
  * `:missing_at_provider` — local terminal/in-flight state with no provider record — critical, needs manual review.
  * `:missing_locally`     — provider object with no local row at all (the restore-orphan case) — critical, needs manual review.
  * `:unresolvable`        — can't be queried (e.g. no provider uid) — needs manual review.
  * `:errors`              — the provider query itself failed.
  * `:skipped`             — not queried because the provider circuit breaker was open.

# `merge`

# `new`

# `outcomes`

# `tally`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
