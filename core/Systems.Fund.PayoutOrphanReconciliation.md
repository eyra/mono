# `Systems.Fund.PayoutOrphanReconciliation`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/fund/payout_orphan_reconciliation.ex#L1)

Provider→local reconciliation for payouts: lists the withdrawals and transfers
the provider created inside the window and flags any whose payout has no local
row at all.

This is the inverse of `Fund.PayoutReconciliation`, which starts from local
rows and so can only ever check payouts we already know about. A backup restore
that rolls back the window in which a payout row was created leaves money moved
at the provider with no local record — invisible to a local-first scan, and
findable only by enumerating the provider side.

Both legs identify their payout through a reference derived from the payout's
restore-stable `uid` (`Fund.PayoutModel.withdrawal_key/1` and
`transfer_key/1`), which is what makes the reverse match possible at all: the
serial id a restore rewinds never appears in it.

Donation charges are scanned here too, against `Fund.DonationModel`. They are
not a payout, but they land in the very same provider transfer listing (both
are charges at OPP), so a pass that only understood `payout=` references would
report every donation as unresolvable and bury the real findings.

Detection only. An orphan means real money moved with no ledger entry, so it is
recorded as a `:missing_locally` finding for manual resolution — recreating the
local row from provider data would fabricate bookkeeping and risk paying twice.
Driven by `Systems.Payment.ReconciliationWorker`.

# `run`

Scans provider withdrawals and transfers created in the
`[max_age_days, min_age_minutes]` window, returning the updated state.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
