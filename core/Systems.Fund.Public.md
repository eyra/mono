# `Systems.Fund.Public`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/fund/_public.ex#L1)

# `apply_withdrawal_status`

Applies a provider withdrawal status change to the linked payout and its rewards.
Idempotent: terminal payouts short-circuit. Returns `{:ok, payout}` when a
payout was found, `{:ok, nil}` when none matched the uid, or `{:error, reason}`.

# `approve_pending_rewards`

# `approve_reward`

Approves a reward and pays it out, inside the caller's Multi. The status
flip and payment Bookkeeping entry commit atomically with whatever else
the caller is doing.

Idempotent on `:approved`/`:paid`. Overrides a `:rejected` reward by
flipping it back to `:approved` and paying from `fund.available` (the
deposit was already rolled back when the reward was rejected). The
balance guard on the override path mirrors `guard_fund_balance` on
reserve: only `:legal` currencies are constrained by real available
balance; `:virtual` currencies have no such constraint.

# `auth_module`

# `complete_transaction`

Completes a transaction after successful payment.
In one atomic Multi:
1. Update transaction status to :completed
2. Create bookkeeping entry (debit CurrencyLedger.inbound, credit Fund.available)
3. Increment assignment subject_count

Money stays on the user's OPP merchant. Our bookkeeping is the source of truth
for fund allocation. OPP withdrawals happen at payout time (UC-OPP-06).

Status handling: `:pending` and `:failed` transactions are both completed by
this function. The `:failed → :completed` upgrade resolves the race where the
expiration worker marks a transaction failed before a late webhook arrives —
the researcher's payment did succeed at OPP and we credit it. Only
`:completed` transactions are refused (idempotency on duplicate webhooks).

# `create_bank_account`

# `create_currency_and_fund`

# `create_fund`

# `create_fund`

# `create_pay_in`

Creates a pending transaction and initiates payment with the payment provider.
Lazily creates an OPP merchant for the user if needed.
Returns {:ok, %{transaction: transaction, payment_url: url}} or {:error, reason}.

# `create_reward`

# `create_reward`

# `expire_stale_pay_ins`

Marks pending pay-in transactions older than `max_age_minutes` as `:failed`.

Returns the number of transactions that were expired.

# `fail_transaction`

# `get!`

# `get_bank_account!`

# `get_by_currency!`

# `get_by_name`

# `get_currency!`

# `get_currency_by_name`

# `get_reward`

# `get_reward`

# `get_reward!`

# `get_transaction_by_provider_uid!`

# `get_wallet_identifier`

# `has_pay_ins?`

# `list`

# `list_bank_accounts`

# `list_confirmed_rewards`

Rewards from `:approved` onwards — the owner has confirmed the
contribution and everything downstream (pending payout, paid).

# `list_currencies`

# `list_currencies_by_type`

# `list_owned`

# `list_owned_by_currency`

# `list_paid_rewards`

# `list_payouts_for_user`

All payouts (withdrawal requests) for a participant, newest first. Powers the
"Uitbetalingen > Overzicht" history on the account page.

# `list_pending_approvals`

# `list_rejected_rewards`

# `list_rewards`

# `list_transactions_by_fund`

# `list_wallets`

# `make_deposit`

# `make_test_deposit`

# `mark_pending_approval`

Marks a reserved reward as awaiting owner approval, inside the caller's
Multi. Single guarded UPDATE — matches only if the reward's current status
is `:reserved`, so it's idempotent (no-op if already past `:reserved`).

# `move_wallet_balance`

# `move_wallet_balance`

# `multiply_rewards`

# `payout_eligibility`

Pure pre-flight threshold check (no side effects), used by `prepare_payout/2`.

# `payout_reward`

# `payout_status`

```elixir
@spec payout_status(Systems.Account.User.t()) ::
  :none | :in_progress | :retryable | :manual
```

The participant's payout situation for display, so the home card can surface a
stranded payout the reward-status columns don't show:

  * `:none`        — no unresolved payout; the normal "Uitbetalen" flow applies.
  * `:in_progress` — issued and awaiting the bank; nothing for the user to do.
  * `:retryable`   — stranded but recoverable; a "retry" resumes it.
  * `:manual`      — an unconfirmed transfer that only support can resolve.

# `payout_threshold_cents`

Minimum approved balance (in cents) required to request a payout — €5.

# `pending_rewards`

# `pending_rewards`

# `pending_rewards_query`

# `prepare_payout`

Side-effecting pre-handoff check (UC-OPP-06.A1): ensures merchant + bank
account exist, then reports payout readiness via `payout_ready_for/1`.

# `print_auth_roles`

# `reconcile_orphaned_payouts`

Flags provider withdrawals and transfers that have no local payout row.
See `Systems.Fund.PayoutOrphanReconciliation`.

# `reconcile_orphaned_transactions`

Flags provider transactions that have no local pay-in row.
See `Systems.Fund.TransactionOrphanReconciliation`.

# `reconcile_pending_payouts`

Reconciles `:pending` payouts against the payment provider.
See `Systems.Fund.PayoutReconciliation`.

# `reconcile_transactions`

# `reject_reward`

Rejects a reward and returns the reserved money to the assignment fund,
inside the caller's Multi. The status flip and deposit reversal commit
atomically with whatever else the caller is doing.

On a `:rejected` reward this is a no-op; on `:approved`/`:paid` it fails
the surrounding transaction with `{:error, :reward_already_approved}`
(rather than raising deep in `rollback_deposit/2`). The status flip is
a guarded compare-and-swap, so a concurrent transition makes this a
safe rollback.

The reviewer's rejection reason lives on `Assignment.Participation`;
Fund only records the outcome.

# `request_donation`

Donates every `:approved` reward the participant holds in `currency` to Eyra,
waiving the right to have them paid out (UC-OPP-07).

The money already sits on the platform merchant, so unlike a payout there is
nothing to transfer to the participant and nothing to withdraw: a single
provider charge settles it as the operator's own. Rewards go
`:approved -> :donating -> :donated`, locked the same way a payout locks them.

The lock is what prevents a double charge; the idempotency key only prevents a
replay of the same donation. Changing either mechanism means checking the other.

No threshold and no KYC. `@payout_threshold_cents` exists because withdrawals
cost money; a donation has no such floor, so donating €0.50 is fine.

Returns `{:ok, donation}`, or:
  * `{:error, :nothing_to_donate}` — no approved rewards in this currency
  * `{:error, :no_platform_merchant}` — `OPP_MERCHANT_UID` unset
  * `{:error, :lock_failed}` — a concurrent payout or donation took the rewards
  * `{:error, {:opp_failed, error}}` — definitively rejected, lock released
  * `{:error, {:opp_uncertain, error}}` — outcome unknown; the rewards stay
    `:donating` for manual resolution (see `Fund.DonationModel`)

# `request_payout`

Requests a payout for all of the participant's `:approved` rewards: locks
them, then transfers and withdraws via the payment provider. Returns `{:ok, result}` or
`{:error, reason}`.

# `resume_payout`

Drives a stranded payout forward, without ever re-moving money.
See `Systems.Fund.PayoutWithdrawal.resume/1`.

# `reward_has_outstanding_deposit?`

# `rewarded_amount`

# `rollback_deposit`

# `rollback_deposit`

# `start_bank_verification`

```elixir
@spec start_bank_verification(Systems.Account.User.t()) ::
  {:bank, String.t()} | :verified | {:error, term()}
```

Onboarding entry point for the "Toevoegen" action: ensures the merchant + bank
account exist (creating them if needed) and reports how to continue. Independent
of payout-threshold eligibility — a participant can verify their bank before
earning anything.

Returns `{:bank, verification_url}` (drive the seamless iDEAL picker),
`:verified`, or `{:error, reason}`.

The arity-2 form pushes the given phone to the merchant — used when collecting
it in the phone form. The arity-1 form is for the already-on-file case and does
not re-push (the phone was pushed to OPP when first collected).

# `start_bank_verification`

```elixir
@spec start_bank_verification(Systems.Account.User.t(), String.t() | nil) ::
  {:bank, String.t()} | :verified | {:error, term()}
```

# `summarize_rewards`

Per-status reward totals (in cents) for the home rewards-summary card.

# `verification_status`

```elixir
@spec verification_status(Systems.Account.User.t()) ::
  :not_verified | :pending | :verified
```

Read-only KYC/bank-account verification status for the account page's
"Bankrekening" section. Never creates a merchant: a user without a
`merchant_uid` (never started a payout) is simply `:not_verified`.

Unlike `payout_ready_for/2` (which collapses "no redirect URL yet" into
`:kyc_unavailable`), this distinguishes `:pending` — a bank account submitted
to OPP that is still being reviewed — so the UI can show "Wordt geverifiëerd".

# `wallet_is_active?`

# `wallet_is_passive?`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
