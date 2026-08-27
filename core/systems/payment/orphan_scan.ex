defmodule Systems.Payment.OrphanScan do
  @moduledoc """
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
  """
  alias Systems.Payment.ReconciliationState, as: State

  require Logger

  @doc """
  Whether an object is old enough to judge.

  An object created moments ago may have a local row committing right now, so
  flagging it would flap. One with no readable creation stamp is kept rather than
  dropped: the pass exists to surface unknown objects, and an unparseable date
  must not silently exclude one.
  """
  def settled?(%{created: nil}, _newest), do: true
  def settled?(%{created: created}, newest), do: DateTime.compare(created, newest) != :gt

  @doc """
  Unwraps a provider listing into `{objects, state}`.

  A failed or skipped listing yields no objects and is tallied once for the whole
  listing — there are no rows to attribute it to, and the alternative (silently
  scanning nothing) would read as "no orphans found". `source` names the listing
  for the log line and the finding.

  A truncated listing is the same hazard in subtler form: the objects it did
  return are still scanned, but the run records that the sweep never reached the
  end, so a partial pass cannot be read off the tally as a clean one.
  """
  def take_listing({{:ok, objects}, state}, _subject_type, _source), do: {objects, state}

  def take_listing({{:truncated, objects}, state}, subject_type, source) do
    Logger.error(
      "[Payment] orphan scan: #{source} listing truncated at the provider paging cap — " <>
        "#{length(objects)} scanned, anything older was never seen, manual review"
    )

    {objects,
     record(
       state,
       :errors,
       subject_type,
       nil,
       %{error: "listing truncated at paging cap"},
       source
     )}
  end

  def take_listing({:circuit_open, state}, subject_type, source),
    do: {[], record(state, :skipped, subject_type, nil, %{reason: "circuit_open"}, source)}

  def take_listing({{:error, reason}, state}, subject_type, source) do
    Logger.warning("[Payment] orphan scan: listing #{source} failed: #{inspect(reason)}")
    {[], record(state, :errors, subject_type, nil, %{error: inspect(reason)}, source)}
  end

  def take_listing({:not_found, state}, subject_type, source) do
    Logger.warning("[Payment] orphan scan: #{source} listing returned not_found")
    {[], record(state, :errors, subject_type, nil, %{error: "listing not_found"}, source)}
  end

  @doc """
  Tallies `outcome` and appends a finding for `object`, merging `details` over
  the identifying fields read off the object itself.

  `source` names the provider listing the object came from. It is stored as a
  string so an in-memory finding and one read back from the database — where the
  details map round-trips through JSON — carry the same value.
  """
  def record(state, outcome, subject_type, object, details, source \\ nil) do
    finding = %{
      subject_type: subject_type,
      subject_id: nil,
      provider_uid: provider_uid(object),
      local_status_before: nil,
      provider_status: provider_status(object),
      outcome: outcome,
      details: details |> with_source(source) |> merge_object_details(object)
    }

    state
    |> State.tally(outcome)
    |> State.add_finding(finding)
  end

  defp with_source(details, nil), do: details
  defp with_source(details, source), do: Map.put(details, :source, to_string(source))

  defp merge_object_details(details, object), do: Map.merge(object_details(object), details)

  defp provider_uid(%{uid: uid}), do: uid
  defp provider_uid(nil), do: nil

  defp provider_status(%{raw_status: raw_status}), do: raw_status
  defp provider_status(_object), do: nil

  defp object_details(%{reference: reference, amount: amount, created: created}) do
    %{reference: reference, amount: amount, created: iso8601(created)}
  end

  defp object_details(%{created: created}), do: %{created: iso8601(created)}
  defp object_details(_object), do: %{}

  defp iso8601(nil), do: nil
  defp iso8601(%DateTime{} = created), do: DateTime.to_iso8601(created)
end
