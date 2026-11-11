# `Systems.Fund.TransactionOrphanReconciliation`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/fund/transaction_orphan_reconciliation.ex#L1)

Provider→local reconciliation for pay-ins: lists the transactions the provider
created inside the window and flags any with no local row.

The inverse of `Fund.TransactionReconciliation`, which starts from local rows
and so can only check pay-ins we already know about. A backup restore that
rolls back the window in which a transaction row was created leaves a payment
taken at the provider with no local record — invisible to a local-first scan.

Matching is on the transaction's `idempotence_key`, which the adapter sends to
the provider as `metadata.reference`. `invoice_id` cannot serve: it comes from
a Postgres sequence a restore rewinds, so post-restore a new transaction is
handed the same invoice_id an orphan already holds, and matching on it would
pair the orphan with an unrelated local row.

Transactions created before the reference metadata shipped carry no reference
and cannot be matched either way. They are reported as `:unresolvable` rather
than passed over, so the gap is visible rather than silently read as "no
orphans" — expect a non-zero count for the first window after deploy, draining
to zero as those transactions age out of it.

Detection only, for the same reason as `Fund.PayoutOrphanReconciliation`:
money moved with no ledger entry needs a person, not an automatic write.
Driven by `Systems.Payment.ReconciliationWorker`.

# `run`

Scans provider transactions created in the `[max_age_days, min_age_minutes]`
window, returning the updated state.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
