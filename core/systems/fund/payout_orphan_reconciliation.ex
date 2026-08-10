defmodule Systems.Fund.PayoutOrphanReconciliation do
  @moduledoc """
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

  Detection only. An orphan means real money moved with no ledger entry, so it is
  recorded as a `:missing_locally` finding for manual resolution — recreating the
  local row from provider data would fabricate bookkeeping and risk paying twice.
  Driven by `Systems.Payment.ReconciliationWorker`.
  """
  import Ecto.Query

  require Logger

  alias Core.Repo
  alias Systems.Fund
  alias Systems.Payment
  alias Systems.Payment.OrphanScan
  alias Systems.Payment.ReconciliationState, as: State

  # Anchored to a field boundary, not to the start of the reference: the
  # `payout=` pair is not guaranteed to be the first one in the key.
  @payout_uid ~r/(?:^|,)payout=(?<uid>[^,]+)/

  @doc """
  Scans provider withdrawals and transfers created in the
  `[max_age_days, min_age_minutes]` window, returning the updated state.
  """
  def run(opts, %State{} = state) do
    {oldest, newest} = Payment.Public.reconciliation_scan_window(opts)

    {withdrawals, state} = list_recent_withdrawals(state, oldest)
    state = reconcile_leg(withdrawals, :withdrawal, newest, state)

    {transfers, state} = list_recent_transfers(state, oldest)
    reconcile_leg(transfers, :transfer, newest, state)
  end

  defp list_recent_withdrawals(state, oldest) do
    state
    |> Payment.Public.reconcile_list_recent_withdrawals(oldest)
    |> OrphanScan.take_listing(:payout, :withdrawal)
  end

  defp list_recent_transfers(state, oldest) do
    state
    |> Payment.Public.reconcile_list_recent_transfers(oldest)
    |> OrphanScan.take_listing(:payout, :transfer)
  end

  defp reconcile_leg(objects, leg, newest, state) do
    objects
    |> Enum.filter(&OrphanScan.settled?(&1, newest))
    |> classify_references(leg)
    |> check_against_local(leg, state)
  end

  defp classify_references(objects, leg) do
    Enum.map(objects, fn object -> {payout_uid(object, leg), object} end)
  end

  # Only a UUID is accepted. Pre-`e4dbe4b6a` references carry the serial payout
  # id, which a restore rewinds — matching on one could pair a provider object
  # with an unrelated local payout, so it is reported rather than guessed at.
  defp payout_uid(%{reference: reference}, leg) when is_binary(reference) do
    with %{"uid" => uid} <- Regex.named_captures(@payout_uid, reference),
         {:ok, uid} <- Ecto.UUID.cast(uid) do
      {:ok, uid}
    else
      _ -> {:error, unparseable_reason(reference, leg)}
    end
  end

  defp payout_uid(_object, _leg), do: {:error, "no reference"}

  defp unparseable_reason(reference, leg) do
    "unrecognised #{leg} reference format: #{reference}"
  end

  defp check_against_local(pairs, leg, state) do
    known = known_payout_uids(pairs)
    Enum.reduce(pairs, state, &check_one(&1, leg, known, &2))
  end

  defp known_payout_uids(pairs) do
    uids = for {{:ok, uid}, _object} <- pairs, do: uid

    case uids do
      [] -> MapSet.new()
      uids -> uids |> query_payout_uids() |> MapSet.new()
    end
  end

  defp query_payout_uids(uids) do
    from(p in Fund.PayoutModel, where: p.uid in ^uids, select: p.uid)
    |> Repo.all()
  end

  defp check_one({{:error, reason}, %{uid: uid} = object}, leg, _known, state) do
    Logger.error("[Fund] orphan scan: #{leg} #{uid} — #{reason}")
    record(state, :unresolvable, leg, object, %{reason: reason})
  end

  defp check_one({{:ok, payout_uid}, %{uid: uid} = object}, leg, known, state) do
    if MapSet.member?(known, payout_uid) do
      State.tally(state, :verified)
    else
      Logger.error(
        "[Fund] orphan scan: #{leg} #{uid} references payout #{payout_uid} " <>
          "which has no local row — money moved with no ledger entry, manual review"
      )

      record(state, :missing_locally, leg, object, %{payout_uid: payout_uid})
    end
  end

  defp record(state, outcome, leg, object, details),
    do: OrphanScan.record(state, outcome, :payout, object, details, leg)
end
