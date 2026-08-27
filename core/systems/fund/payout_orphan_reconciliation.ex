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

  Donation charges are scanned here too, against `Fund.DonationModel`. They are
  not a payout, but they land in the very same provider transfer listing (both
  are charges at OPP), so a pass that only understood `payout=` references would
  report every donation as unresolvable and bury the real findings.

  Detection only. An orphan means real money moved with no ledger entry, so it is
  recorded as a `:missing_locally` finding for manual resolution — recreating the
  local row from provider data would fabricate bookkeeping and risk paying twice.
  Driven by `Systems.Payment.ReconciliationWorker`.
  """
  import Ecto.Query

  alias Core.Repo
  alias Systems.Fund
  alias Systems.Payment
  alias Systems.Payment.OrphanScan
  alias Systems.Payment.ReconciliationState, as: State

  require Logger

  # Anchored to a field boundary, not to the start of the reference: the
  # `payout=` pair is not guaranteed to be the first one in the key.
  @subject_uid ~r/(?:^|,)(?<kind>payout|donation)=(?<uid>[^,]+)/

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
    Enum.map(objects, fn object -> {subject_uid(object, leg), object} end)
  end

  # Only a UUID is accepted. Pre-`e4dbe4b6a` references carry the serial payout
  # id, which a restore rewinds — matching on one could pair a provider object
  # with an unrelated local payout, so it is reported rather than guessed at.
  defp subject_uid(%{reference: reference}, leg) when is_binary(reference) do
    with %{"kind" => kind, "uid" => uid} <- Regex.named_captures(@subject_uid, reference),
         {:ok, uid} <- Ecto.UUID.cast(uid) do
      {:ok, {kind_of(kind), uid}}
    else
      _ -> {:error, unparseable_reason(reference, leg)}
    end
  end

  defp subject_uid(_object, _leg), do: {:error, "no reference"}

  defp kind_of("payout"), do: :payout
  defp kind_of("donation"), do: :donation

  defp unparseable_reason(reference, leg) do
    "unrecognised #{leg} reference format: #{reference}"
  end

  defp check_against_local(pairs, leg, state) do
    known = known_subjects(pairs)
    Enum.reduce(pairs, state, &check_one(&1, leg, known, &2))
  end

  # One query per kind, not per object: a scan window holds at most a few
  # hundred references and both kinds key on a `uid` column.
  defp known_subjects(pairs) do
    for_result = for({{:ok, subject}, _object} <- pairs, do: subject)

    for_result
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> Enum.flat_map(&query_subject_uids/1)
    |> MapSet.new()
  end

  defp query_subject_uids({kind, uids}) do
    from(r in schema(kind), where: r.uid in ^uids, select: r.uid)
    |> Repo.all()
    |> Enum.map(&{kind, &1})
  end

  defp schema(:payout), do: Fund.PayoutModel
  defp schema(:donation), do: Fund.DonationModel

  defp check_one({{:error, reason}, %{uid: uid} = object}, leg, _known, state) do
    Logger.error("[Fund] orphan scan: #{leg} #{uid} — #{reason}")
    record(state, :unresolvable, :payout, leg, object, %{reason: reason})
  end

  defp check_one({{:ok, {kind, subject_uid} = subject}, %{uid: uid} = object}, leg, known, state) do
    if MapSet.member?(known, subject) do
      State.tally(state, :verified)
    else
      Logger.error(
        "[Fund] orphan scan: #{leg} #{uid} references #{kind} #{subject_uid} " <>
          "which has no local row — money moved with no ledger entry, manual review"
      )

      record(state, :missing_locally, kind, leg, object, subject_details(kind, subject_uid))
    end
  end

  defp subject_details(:payout, uid), do: %{payout_uid: uid}
  defp subject_details(:donation, uid), do: %{donation_uid: uid}

  defp record(state, outcome, subject_type, leg, object, details),
    do: OrphanScan.record(state, outcome, subject_type, object, details, leg)
end
