# Reward Pay-out Flow — Implementation Plan

Branch: `feat/reward-payout-UC-OPP-5` (branched from `feat/fund-assignment-UC-OPP-1`)
Epic: OPP Phase 2 — Use Cases ([9644849214](https://3.basecamp.com/5734045/buckets/35926565/todos/9644849214))

## Goal

Build the complete reward pay-out flow on top of Phase 1 (Fund Assignment / pay-in) that is already in testing on `eyra-next-test2`:

1. Participant completes assignment → reward **reserved**.
2. Researcher (or auto-approval) **approves** the reward → money lands in the participant's **wallet**.
3. Participant can either **request a payout** (wallet → bank via OPP withdrawal) or **donate** to Eyra (no KYC required).

Money flows between three tiers, tracked in double-entry Bookkeeping:

- **AssignmentBudget** — `fund` + `reserve` accounts (reserve = pending approval)
- **Wallet** — `fund` + `reserve` accounts (reserve = locked during payout)
- **ProviderAccount** — `merchant` (incoming) + `payouts` (outgoing) at OPP

## Scope — tickets in this flow

| ID | Type | Title | Size | Status |
|---|---|---|---|---|
| [9665371726](https://3.basecamp.com/5734045/buckets/35926565/todos/9665371726) | UC-OPP-04 | Participant Starts Assignment | M | Spec |
| [9701092786](https://3.basecamp.com/5734045/buckets/35926565/todos/9701092786) | UC-OPP-09 | Participant Completes Assignment | M | Spec |
| [9665063302](https://3.basecamp.com/5734045/buckets/35926565/todos/9665063302) | UC-OPP-05 | Approve Reward | M | Spec |
| [9665064501](https://3.basecamp.com/5734045/buckets/35926565/todos/9665064501) | UC-OPP-06 | Request Payout | L | Spec |
| [9665065270](https://3.basecamp.com/5734045/buckets/35926565/todos/9665065270) | UC-OPP-07 | Request Donation | M | Spec |
| [9665372269](https://3.basecamp.com/5734045/buckets/35926565/todos/9665372269) | SF-OPP-08 | Check Budget Capacity | S | Spec |
| [9672501038](https://3.basecamp.com/5734045/buckets/35926565/todos/9672501038) | UC-OPP-10 | Create Provider Account (admin) | — | Spec |

System Functions (behaviours called from use cases):
- **SF-OPP-03** Reserve Budget on Completion (triggered by UC-OPP-09)
- **SF-OPP-04** Send Approval Notification (trigger: reward reserved)
- **SF-OPP-05** Auto-Approve After Timeout (Oban, 2 weeks)
- **SF-OPP-06** Check Payout Threshold (≥ €5 PaNL)
- **SF-OPP-07** Auto-Donate After Inactivity (Oban, 6 months, with reminder)
- **SF-OPP-08** Check Budget Capacity (Promotion page)

## Current state — what we can build on

Already implemented in `feat/fund-assignment-UC-OPP-1` (pay-in flow) and Phase 1:

- `Systems.Fund` — `Fund.Model` with `available` + `pending` Bookkeeping accounts, `CurrencyLedgerModel`, `RewardModel`, `BankAccountModel`, wallet views.
- `Systems.Budget.Public` — `create_pay_in/complete_transaction/fail_transaction/expire_stale_pay_ins` with partner fee, invoice ID, `transaction_id` + `idempotence_key`, Ecto.Multi atomicity.
- `Systems.Payment.Provider` (OPP) — already exposes **`create_withdrawal/3` and `get_withdrawal/1`** (the payout primitives we need), plus `find_merchant_by_email`, webhook verification.
- `PayInExpirationWorker` — Oban cron pattern we can reuse for the approval/inactivity timeouts.
- Webhook controller (`SHA-256` digest + `HMAC-SHA256`, timing-safe compares, `SKIP_WEBHOOK_VERIFICATION` dev bypass).
- `Systems.Assignment.Public.payout_participant/2` — **legacy** path that auto-pays on task completion (no approval step). Will be replaced by the reserve-then-approve flow.

Key dependency to clarify: today, `assignment/_switch.ex:448 payout_participants/3` fires on crew-task status transition and immediately credits the wallet. The new flow must intercept that same signal and instead **reserve** the reward pending approval.

## Architecture — bookkeeping entries per step

Source: epic thread "Money Flow: Three-tier budget model" (Flux, 2026-03-20).

| Step | Debit | Credit |
|---|---|---|
| Pay-in (done) | `ProviderAccount.merchant` | `ResearcherBudget.fund` (= `AssignmentBudget.fund`, single-budget model) |
| Complete (SF-OPP-03) | `AssignmentBudget.fund` | `AssignmentBudget.reserve` |
| Approve (UC-OPP-05) | `AssignmentBudget.reserve` | `Wallet.fund` |
| Reject (UC-OPP-05.A1) | `AssignmentBudget.reserve` | `AssignmentBudget.fund` |
| Payout lock (UC-OPP-06) | `Wallet.fund` | `Wallet.reserve` |
| Payout settle | `Wallet.reserve` | `ProviderAccount.payouts` |
| Donate (UC-OPP-07) | `Wallet.fund` | donation destination |

Every step must be an `Ecto.Multi` with its own `idempotence_key` and dispatched `Signal.multi_dispatch` event.

## Phased plan

The scope is large enough to split into **three PRs**. Each PR should be independently deployable to `eyra-next-test2`.

### Phase 1 — Reserve & Approve (UC-OPP-09, UC-OPP-05, SF-OPP-03/04/05, UC-OPP-04/SF-OPP-08)

**Why first:** unblocks everything downstream and is a self-contained behavioural change (reserve instead of instant pay).

- [ ] **Data model**
  - Add `reserve` account type on `AssignmentBudget` (Fund.Model: add second Bookkeeping account, mirror of `available`/`pending`).
  - Add `RewardModel.status` state machine: `reserved → approved | rejected | auto_approved`, plus `reserved_at`, `approved_at`, `approved_by_id` columns.
  - Migration + backfill (existing rewards → `approved` / `approved_at = inserted_at`).
- [ ] **SF-OPP-03 Reserve on completion** (`Systems.Fund.Public.reserve_reward/3`)
  - Ecto.Multi: debit `AssignmentBudget.fund`, credit `AssignmentBudget.reserve`, update reward status.
  - Replace `Assignment.Public.payout_participant/2` call site in `assignment/_switch.ex:448` to call `reserve_reward/3` instead.
  - Guard: if `Fund.available < amount` → log + notify admins (UC-OPP-09.A1).
- [ ] **SF-OPP-04 Send Approval Notification** — reuse existing notification system; trigger from `{:reward, :reserved}` signal.
- [ ] **UC-OPP-05 Approve Reward UI**
  - Researcher-side approval screen (design: Neo) — list of pending rewards per assignment, Approve / Reject buttons.
  - `Fund.Public.approve_reward/2` / `reject_reward/2` (Multi + dispatch).
- [ ] **SF-OPP-05 Auto-Approve Worker**
  - `Fund.AutoApproveWorker` Oban cron (daily?) — finds rewards with `reserved_at < now - 14 days`, calls `approve_reward` with `auto_approved` source.
  - Add to `ENABLED_OBAN_PLUGINS` docs; make opt-in like `pay_in_expiration`.
- [ ] **UC-OPP-04 participant flow guards**
  - **SF-OPP-08** — on Promotion page: `Fund.Public.has_capacity?/2` (checks `fund.available >= reward_per_participant`). Show "Assignment full" when not.
  - Defensive check at CrewPage: if `fund.available = 0` → block + notify PaNL admins.
- [ ] **Tests**
  - `Fund.Public.reserve_reward/3` happy + insufficient-fund path.
  - `approve_reward / reject_reward` — state transitions, bookkeeping entries, signal dispatch.
  - Auto-approve worker — enqueue + run + skip already-approved.
  - Feature test: researcher approves → wallet balance increases; researcher rejects → budget is returned.
  - Feature test: participant sees "full" on Promotion when capacity exhausted.

### Phase 2 — Payout (UC-OPP-06, SF-OPP-06)

**Why second:** requires Phase 1 rewards in wallet, and the provider consolidation call pattern.

- [ ] **Architecture note** — rewards are tracked per-assignment internally; only at payout time do we consolidate all `Wallet.fund` entries into a single OPP transaction. This avoids per-reward provider fees.
- [ ] **Payout entity** — `Fund.PayoutModel` (status: `pending | transferring | withdrawing | completed | failed`, amount, currency, provider_uid for withdrawal, wallet snapshot, `idempotence_key`).
- [ ] **SF-OPP-06 threshold check** — `Fund.Public.can_payout?(wallet)` (≥ €5 PaNL).
- [ ] **UC-OPP-06 Payout lifecycle**
  - `Fund.Public.request_payout(wallet, user)` — Multi: lock funds (`Wallet.fund` → `Wallet.reserve`), insert Payout record, dispatch `{:payout, :requested}`.
  - Payment Provider handoff screen (UX copy in spec).
  - **Provider API call 1 — transfer**: debit `Wallet.reserve`, credit `ProviderAccount.payouts`. Uses `Payment.Provider` (a new `create_transfer/3` behaviour may be required — OPP supports it via API; current `create_withdrawal` only covers bank payout).
  - **Provider API call 2 — withdrawal**: `Payment.Provider.create_withdrawal/3`.
  - Webhook handler: on `payout.completed` → finalise Payout; on `payout.failed` → reverse lock (`Wallet.reserve → Wallet.fund`), schedule retry (Oban).
- [ ] **UC-OPP-06.A1 KYC flow** — handled entirely by OPP; we just pass the user to the provider and handle the "merchant created" webhook the same way as in pay-in.
- [ ] **Wallet UI** (designs in Neo's comments on issue 9664904389 / 9665064501)
  - Dashboard with available balance, list of past payouts, Payout button (disabled if < €5), Donate button.
- [ ] **Tests**
  - Threshold guard (below / at threshold).
  - Lock + reverse on failure.
  - Transfer + withdrawal atomicity.
  - Idempotency under duplicate webhooks.
  - Webhook retry / late webhook scenarios (mirrors Phase 1 pay-in pattern).

### Phase 3 — Donation & inactivity (UC-OPP-07, SF-OPP-07)

**Why last:** relies on Wallet being in place and shares the notification infrastructure with Phase 1.

- [ ] **UC-OPP-07 Donate**
  - `Fund.Public.donate_reward(wallet, user)` — Multi: debit `Wallet.fund`, credit donation destination.
  - Waiver confirmation modal (explicit consent — spec: "Participant explicitly waives the right to receive the amount as payout").
  - No KYC / provider call — purely internal bookkeeping transfer.
- [ ] **SF-OPP-07 Auto-donate worker**
  - Oban cron: find wallet entries older than **6 months** (placeholder pending Open Question — see below), send reminder email at 5 months, donate at 6.
  - FIFO expiry — oldest entries donated first.
- [ ] **UI**
  - Researcher "Participants" tab: alert for participants with expiring money (design linked in Neo's comment).
  - Participant wallet: reminder email (1 month before) + expiring-budget email.
- [ ] **Tests**
  - Donate happy path.
  - Auto-donate: triggers at 6m, reminder at 5m, skipped if payout requested.
  - FIFO expiry.

### Phase 0 (prerequisite) — Provider Account scaffolding (UC-OPP-10)

Only needed if the current `BankAccount` model cannot support the `payouts` Bookkeeping account required by Phases 2–3. Investigate first:

- [ ] Can the existing `Fund.BankAccountModel` be extended with a `payouts` account + `provider` field?
- [ ] If yes: in-place migration (default `provider: "opp"`, create payouts Bookkeeping account for each row). If no: add `ProviderAccountModel` alongside with a deprecation shim on `BankAccount`.
- [ ] Admin UI for creating provider accounts (System Admin → Provider Accounts).

## Open questions (to raise before/during implementation)

From the tickets:

1. **UC-OPP-05**: What does the participant see when a researcher rejects a reward? (Rejection flow UX — not designed yet.)
2. **UC-OPP-06**: Fee percentage for Eyra/PaNL on payouts?
3. **UC-OPP-06**: Monthly payout of Eyra fees or per-transaction?
4. **UC-OPP-07**: Dormant balance policy — **1, 3, or 6 months**?
5. **UC-OPP-07**: What happens if a PaNL participant stays below €5 indefinitely? (Under-threshold expiry.)

Added by this plan:

6. Provider `create_transfer` behaviour is not yet in `Payment.Provider` — confirm OPP endpoint and add to the behaviour before Phase 2.
7. Does Phase 2 require consolidation across multiple `CurrencyLedger`s, or can we assume a single-currency payout? (The entity model is currency-scoped; default answer: payout is per-currency.)
8. `ResearcherBudget` vs `AssignmentBudget` — the epic thread shows a three-tier model, but the current codebase has a single fund-per-assignment model. Phase 1 kept it single-tier; confirm with @melle that Phase 2 does not re-introduce the researcher-level budget.

## Testing strategy

- **Unit**: every `Fund.Public` function — happy path + guard failure.
- **Integration**: reserve → approve → payout end-to-end, with Signal dispatches and bookkeeping invariants asserted.
- **Feature (Wallaby)**: two-session test mirroring `test/features/panl_study_advert_test.exs` — researcher approves, participant sees wallet update, participant requests payout (OPP mock).
- **Webhook**: reuse `test/systems/payment/provider/opp/webhook_test.exs` patterns; add payout-completed / payout-failed fixtures.
- **Oban**: test the cron workers in isolation (`Oban.Testing`).

## Deployment

- Each phase ships to `eyra-next-test2` with `SKIP_WEBHOOK_VERIFICATION=true` (matches Phase 1 pay-in situation) and `PAYMENT_PROVIDER=opp`.
- Before production: audit `SKIP_WEBHOOK_VERIFICATION` across all fly apps (carried over from Phase 1 review).
- Oban plugins (`auto_approve`, `auto_donate`) must be added to `ENABLED_OBAN_PLUGINS` on each environment — otherwise the timers silently never fire.

## Non-goals for this branch

- Multi-currency payout consolidation (single currency per payout request).
- Withdrawal of Eyra fees (separate back-office flow).
- Changing pay-in flow (Phase 1 stays as-is).
- Rejection flow UX (blocked on design Q1 above).
