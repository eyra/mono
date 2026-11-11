# `Systems.Payment.ReconciliationFindingModel`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/payment/reconciliation_finding_model.ex#L1)

One row per non-trivial reconciliation outcome (anything that was resolved,
could not be resolved, errored, or diverged from the provider). Trivial
outcomes (`:still_pending`, `:verified`) are counted on the run but not stored
here.

`subject_id` is null for `:missing_locally` findings: a provider object with no
local row has no local id to point at, and `provider_uid` plus `details` carry
the identification instead.

# `changeset`

# `outcomes`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
