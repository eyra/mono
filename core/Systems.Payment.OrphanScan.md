# `Systems.Payment.OrphanScan`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/payment/orphan_scan.ex#L1)

Shared scaffolding for the provider→local passes (`Fund.PayoutOrphanReconciliation`,
`Fund.TransactionOrphanReconciliation`, `Account.MerchantOrphanReconciliation`).

Those passes differ only in which provider listing they read, which local
column they diff against, and how they derive a match key. Everything around
that — the min-age guard, turning a listing result into objects plus a tallied
state, and shaping a finding for an object that has no local row — is the same
in each, and lives here.

Findings from these passes always have a null `subject_id`: a provider object
with no local row has no local id to point at, so `provider_uid` and `details`
carry the identification instead.

# `record`

Tallies `outcome` and appends a finding for `object`, merging `details` over
the identifying fields read off the object itself.

`source` names the provider listing the object came from. It is stored as a
string so an in-memory finding and one read back from the database — where the
details map round-trips through JSON — carry the same value.

# `settled?`

Whether an object is old enough to judge.

An object created moments ago may have a local row committing right now, so
flagging it would flap. One with no readable creation stamp is kept rather than
dropped: the pass exists to surface unknown objects, and an unparseable date
must not silently exclude one.

# `take_listing`

Unwraps a provider listing into `{objects, state}`.

A failed or skipped listing yields no objects and is tallied once for the whole
listing — there are no rows to attribute it to, and the alternative (silently
scanning nothing) would read as "no orphans found". `source` names the listing
for the log line and the finding.

A truncated listing is the same hazard in subtler form: the objects it did
return are still scanned, but the run records that the sweep never reached the
end, so a partial pass cannot be read off the tally as a clean one.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
