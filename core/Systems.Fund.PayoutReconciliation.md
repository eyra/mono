# `Systems.Fund.PayoutReconciliation`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/fund/payout_reconciliation.ex#L1)

Reconciliation for participant payouts. Dispatches on `PayoutModel.phase/1`:
a payout in flight is driven to its terminal state from the provider's
withdrawal status; a stranded one (funds moved but the withdrawal never
completed) is healed via `Fund.Public.resume_payout/1`; and only a truly
unrecoverable one (an unconfirmed transfer with no findable charge) is flagged
for manual review. Driven by `Systems.Payment.ReconciliationWorker`.

# `run`

Reconciles payouts in the `[min_age_minutes, max_age_days]` window, returning
the updated state.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
