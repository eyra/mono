# `Systems.Fund.PayoutWithdrawal`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/fund/payout_withdrawal.ex#L1)

The withdrawal leg of a payout, and its recovery.

A payout is a two-leg saga: `Fund.Public` transfers the money from the platform
merchant to the participant's merchant, then hands the payout here to withdraw
it from there to the participant's bank. This module owns the second leg —
issuing the withdrawal on the happy path (`issue/3`), and driving a stranded
payout forward afterwards (`resume/1`).

Nothing here re-moves money. Recovery in particular never blind-replays: the
provider's idempotency keys only de-duplicate for a short window, so instead of
re-issuing a leg and hoping it de-dupes, it asks the provider what actually
happened and acts on that.

# `issue`

Issue the withdrawal for a payout whose funds are already on the participant's
merchant, recording the provider uid.

A provider error is not reverted: the money has moved, so the payout is left
`:pending` for reconciliation rather than unwound.

# `resume`

Drive a stranded payout forward, without ever re-moving money.

Shared entrypoint for the "Retry payout" button and the reconciliation worker.
Dispatches on `PayoutModel.phase/1`:

* `:awaiting_withdrawal` — the money is on the participant's merchant but no
  withdrawal uid was recorded. Look for a withdrawal already at the provider
  (its `reference` carries the payout's key); adopt it if found, otherwise
  issue one.
* `:withdrawal_retryable` — a withdrawal was rejected after the money moved.
  Issue a fresh one under a new attempt (a rejected withdrawal keeps its key).
* `:awaiting_provider` — issued and in flight; nothing to do.
* `:completed` / `:failed` — terminal; nothing to do.
* `:awaiting_transfer` — the transfer was never confirmed. Look for a charge
  already at the provider (its `reference` carries the payout's transfer key);
  adopt it if found and continue to the withdrawal leg. If none is found the
  payout is left for a human: absence is not proof the money never moved, and
  re-issuing on a wrong "no" would charge the platform twice.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
