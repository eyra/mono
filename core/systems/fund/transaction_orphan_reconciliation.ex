defmodule Systems.Fund.TransactionOrphanReconciliation do
  @moduledoc """
  Provider→local reconciliation for pay-ins: lists the transactions the provider
  created inside the window and flags any with no local row.

  The inverse of `Fund.TransactionReconciliation`, which starts from local rows
  and so can only check pay-ins we already know about. A backup restore that
  rolls back the window in which a transaction row was created leaves a payment
  taken at the provider with no local record — invisible to a local-first scan.

  Matching is on the transaction's `idempotence_key`, which the adapter sends to
  the provider as `metadata.reference`. `invoice_id` cannot serve: it comes from
  a Postgres sequence a restore rewinds, so post-restore a new transaction is
  handed the same invoice_id an orphan already holds, and matching on it would
  pair the orphan with an unrelated local row.

  Transactions created before the reference metadata shipped carry no reference
  and cannot be matched either way. They are reported as `:unresolvable` rather
  than passed over, so the gap is visible rather than silently read as "no
  orphans" — expect a non-zero count for the first window after deploy, draining
  to zero as those transactions age out of it.

  Detection only, for the same reason as `Fund.PayoutOrphanReconciliation`:
  money moved with no ledger entry needs a person, not an automatic write.
  Driven by `Systems.Payment.ReconciliationWorker`.
  """
  import Ecto.Query

  alias Core.Repo
  alias Systems.Fund
  alias Systems.Payment
  alias Systems.Payment.OrphanScan
  alias Systems.Payment.ReconciliationState, as: State

  require Logger

  @doc """
  Scans provider transactions created in the `[max_age_days, min_age_minutes]`
  window, returning the updated state.
  """
  def run(opts, %State{} = state) do
    {oldest, newest} = Payment.Public.reconciliation_scan_window(opts)

    {transactions, state} = list_recent_transactions(state, oldest)

    transactions
    |> Enum.filter(&OrphanScan.settled?(&1, newest))
    |> check_against_local(state)
  end

  defp list_recent_transactions(state, oldest) do
    state
    |> Payment.Public.reconcile_list_recent_transactions(oldest)
    |> OrphanScan.take_listing(:transaction, :transaction)
  end

  defp check_against_local(transactions, state) do
    known = known_idempotence_keys(transactions)
    Enum.reduce(transactions, state, &check_one(&1, known, &2))
  end

  defp known_idempotence_keys(transactions) do
    keys = for %{reference: reference} <- transactions, is_binary(reference), do: reference

    case keys do
      [] -> MapSet.new()
      keys -> keys |> query_idempotence_keys() |> MapSet.new()
    end
  end

  defp query_idempotence_keys(keys) do
    Repo.all(
      from(t in Fund.TransactionModel,
        where: t.idempotence_key in ^keys,
        select: t.idempotence_key
      )
    )
  end

  # Logged at info, not error: until the first window after deploy has rolled
  # past, every pre-reference transaction lands here and none of them is a fault.
  defp check_one(%{reference: nil, uid: uid} = transaction, _known, state) do
    Logger.info("[Budget] orphan scan: transaction #{uid} predates reference metadata — skipped")

    record(state, :unresolvable, transaction, %{
      reason: "no reference (created before reference metadata shipped)"
    })
  end

  defp check_one(%{reference: reference, uid: uid} = transaction, known, state) do
    if MapSet.member?(known, reference) do
      State.tally(state, :verified)
    else
      Logger.error(
        "[Budget] orphan scan: transaction #{uid} (#{reference}) has no local row — " <>
          "money moved with no ledger entry, manual review"
      )

      record(state, :missing_locally, transaction, %{idempotence_key: reference})
    end
  end

  defp record(state, outcome, transaction, details),
    do: OrphanScan.record(state, outcome, :transaction, transaction, details, :transaction)
end
