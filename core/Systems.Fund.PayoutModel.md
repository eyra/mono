# `Systems.Fund.PayoutModel`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/fund/payout_model.ex#L1)

Aggregates the `Fund.RewardModel` rows paid out in a single provider withdrawal.

A payout runs a two-leg saga: transfer the money from the platform merchant to
the participant's merchant, then withdraw it from there to their bank.

`status` mirrors what the provider says about the *withdrawal* — `:pending`,
`:completed` or `:failed`. It cannot say how far the saga got, which is a
different question and the one that decides what is safe to do next. That is
what `phase/1` answers, derived from `funds_committed_at` and `provider_uid`.

# `phase`

```elixir
@type phase() ::
  :awaiting_transfer
  | :awaiting_withdrawal
  | :awaiting_provider
  | :withdrawal_retryable
  | :completed
  | :failed
```

# `changeset`

# `phase`

```elixir
@spec phase(
  t :: %Systems.Fund.PayoutModel{
    __meta__: term(),
    amount_cents: term(),
    currency: term(),
    failure_reason: term(),
    funds_committed_at: term(),
    id: term(),
    inserted_at: term(),
    provider_uid: term(),
    rewards: term(),
    status: term(),
    transfer_uid: term(),
    uid: term(),
    updated_at: term(),
    user: term(),
    user_id: term(),
    withdrawal_attempt: term()
  }
) :: phase()
```

How far the payout saga actually got — the question `status` cannot answer.

* `:awaiting_transfer` — the transfer is unconfirmed. It may never have been
  sent, or the provider may have taken it and we lost the response.
* `:awaiting_withdrawal` — the money is on the participant's merchant, but no
  withdrawal uid was recorded. Either none was created, or one was and we lost
  the response. Stranded: the participant sees no payout and no button.
* `:awaiting_provider` — the withdrawal is issued; waiting on a terminal status.
  The normal in-flight state.
* `:withdrawal_retryable` — the provider rejected the withdrawal *after* the
  transfer landed. The money sits on the participant's merchant and the rewards
  stay locked. Recoverable by issuing a fresh withdrawal, never by releasing
  the lock (that would charge the platform twice).
* `:failed` — the transfer was definitively rejected; nothing moved and the
  lock was released. Terminal and safe.
* `:completed` — the money reached the participant's bank.

# `preload_graph`

# `statuses`

# `transfer_key`

Idempotency key for the transfer leg.

It carries no attempt counter, by design: a transfer is never re-issued under a
fresh key. Replaying the *same* key is safe (the provider de-duplicates it, at
least while it still remembers it); minting a new one would move the money a
second time.

# `withdrawal_key`

Idempotency key for the withdrawal leg.

A withdrawal the provider created and then rejected keeps its key, so a retry
must present a fresh one — hence the attempt counter. The `payout=<uid>` prefix
is what a stranded withdrawal is later found by, via its `reference`.

OPP caps a withdrawal's `reference` at 50 characters — the transfer leg carries
its key in `metadata` instead and is not bound by it, hence the terser shape
here. A uuid plus `payout=` already spends 43 of those 50.

# `withdrawal_key_prefix`

Prefix shared by every withdrawal attempt of this payout — used to match a
withdrawal back to its payout when only the provider's `reference` is known.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
