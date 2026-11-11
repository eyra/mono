# `Systems.Payment.ReconciliationWorker`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/payment/reconciliation_worker.ex#L1)

Daily reconciliation sweep. Compares our pay-in (`Budget`) and payout
(`Fund`) state against the payment provider and resolves safe discrepancies — a
lost or failed webhook that left a transaction/payout stuck, or a pay-in the
expiry worker marked `:failed` while the provider actually completed it. It
also flags the critical case the synchronous path can't: local terminal state
the provider has no record of.

Three final provider→local passes run the comparison in the opposite
direction, flagging provider-side payout legs, pay-ins and merchants with no
local row at all — the restore-orphan case, which a local-first scan cannot
see. They run last so a breaker tripped by their whole-listing calls cannot
starve the per-row passes.

Each run is recorded in `reconciliation_runs` (with per-row
`reconciliation_findings`) and emits a `[:payment, :reconciliation, :stop]`
telemetry event so AppSignal tracks discrepancy and resolution counts. Provider
calls are throttled and protected by a circuit breaker via
`Systems.Payment.Reconciliation`.

Window and cadence are overridable via job args (`min_age_minutes`,
`max_age_days`) for manual runs and tests.

# `run`

Runs a reconciliation pass directly (manual / IEx). `opts` may include
`:min_age_minutes`, `:max_age_days` and `:run_type`.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
