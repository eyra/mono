# `Systems.Fund.DonationModel`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/fund/donation_model.ex#L1)

Aggregates the `Fund.RewardModel` rows a participant donated to Eyra in a
single provider charge, waiving the right to have them paid out.

Unlike a payout, a donation is a **one-leg saga**: the money is already on the
platform merchant, so there is nothing to transfer to the participant and
nothing to withdraw. One charge moves it from Eyra-as-merchant to
Eyra-as-partner, and `status` says everything there is to know about it. That
is why there is no `phase/1` here — do not port `Fund.PayoutModel.phase/1`
over, there is no second leg for it to distinguish.

A donation stuck at `:pending` means we do not know whether the provider took
the charge. It is resolved by hand (charges cannot be listed at OPP and there
is no charge webhook), and deliberately so: the worst case is that money which
should sit in Eyra's partner balance still sits in Eyra's merchant balance. No
participant can be underpaid or double-paid by it.

# `changeset`

# `charge_key`

Idempotency key for the charge.

It carries no attempt counter, by design: replaying the same key is safe (the
provider de-duplicates it), while minting a fresh one would take the money a
second time. Also written as the charge's `metadata.reference`, which is what
a stuck donation is found by in the provider dashboard.

# `preload_graph`

# `statuses`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
