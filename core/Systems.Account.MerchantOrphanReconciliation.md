# `Systems.Account.MerchantOrphanReconciliation`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/account/merchant_orphan_reconciliation.ex#L1)

Provider→local reconciliation for merchants: lists the merchants the provider
created inside the window and flags any whose uid no user carries.

This is the restore case that blocks a payout rather than losing one. A
merchant is created at the provider first and its uid written to
`users.merchant_uid` after; a restore that rolls back that write leaves an
account at the provider — possibly a KYC-verified one, with a bank account
attached — that we can no longer reach. The participant sees no payout option
and a fresh merchant cannot be created, because the provider rejects the
duplicate email.

Matching is on the merchant uid alone. The merchant carries no local
identifier that survives a restore: `metadata.user_id` is a serial the restore
rewinds, and the email lives on the merchant's contacts rather than the object
itself. So a finding names the merchant uid and leaves identifying the person
to whoever resolves it, via the provider's own dashboard.

Detection only, like its siblings — binding a user to the wrong merchant would
send their payout to a stranger's bank account, which is worse than the gap it
would be trying to close. Driven by `Systems.Payment.ReconciliationWorker`.

# `run`

Scans provider merchants created in the `[max_age_days, min_age_minutes]`
window, returning the updated state.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
