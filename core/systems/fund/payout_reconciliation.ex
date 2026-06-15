defmodule Systems.Fund.PayoutReconciliation do
  @moduledoc """
  SF-OPP-02 reconciliation for participant payouts: re-applies OPP's current
  withdrawal status to `:pending` payouts whose webhook was lost or failed.
  Driven daily by `Systems.Payment.ReconciliationWorker`.
  """
  import Ecto.Query

  require Logger

  alias Core.Repo
  alias Systems.Fund
  alias Systems.Payment

  @min_age_minutes 60
  @max_age_days 7

  @doc """
  Reconciles `:pending` payouts older than `:min_age_minutes` and newer than
  `:max_age_days` against OPP — driving each to `:completed`/`:failed` when OPP
  is terminal, leaving it when OPP is still in flight. A pending payout without a
  `provider_uid` can't be queried and is reported for manual review.

  Returns a `Systems.Payment.ReconciliationSummary` tally.
  """
  def run(opts \\ []) do
    min_age = Keyword.get(opts, :min_age_minutes, @min_age_minutes)
    max_age = Keyword.get(opts, :max_age_days, @max_age_days)

    stale_pending_payouts(min_age, max_age)
    |> Enum.reduce(Payment.ReconciliationSummary.new(), &reconcile_payout/2)
  end

  defp stale_pending_payouts(min_age_minutes, max_age_days) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    age_cutoff = NaiveDateTime.add(now, -min_age_minutes * 60, :second)
    lookback_cutoff = NaiveDateTime.add(now, -max_age_days * 24 * 60 * 60, :second)

    from(p in Fund.PayoutModel,
      where:
        p.status == :pending and p.inserted_at < ^age_cutoff and p.inserted_at > ^lookback_cutoff
    )
    |> Repo.all()
  end

  defp reconcile_payout(%Fund.PayoutModel{id: id, provider_uid: nil}, summary) do
    Logger.warning(
      "[Fund] reconcile: payout ##{id} :pending with no provider_uid — manual review"
    )

    Payment.ReconciliationSummary.tally(summary, :unresolvable)
  end

  defp reconcile_payout(%Fund.PayoutModel{provider_uid: uid}, summary) do
    outcome =
      case Payment.Public.get_withdrawal(uid) do
        {:ok, %{status: status}} -> resolve(uid, status)
        {:error, reason} -> log_failure("get_withdrawal #{uid}", reason)
      end

    Payment.ReconciliationSummary.tally(summary, outcome)
  end

  # Apply OPP's status; tally what OPP reported, or :errors if the local transition
  # returns/raises an error — so a failed transition isn't logged as resolved and one
  # bad row can't crash the whole sweep.
  defp resolve(uid, status) do
    case Fund.Public.apply_withdrawal_status(uid, status) do
      {:ok, _} -> withdrawal_outcome(status)
      other -> log_failure("apply_withdrawal_status #{uid}", other)
    end
  rescue
    error -> log_failure("apply_withdrawal_status #{uid}", error)
  end

  defp withdrawal_outcome("completed"), do: :resolved_completed
  defp withdrawal_outcome(status) when status in ["failed", "disapproved"], do: :resolved_failed
  defp withdrawal_outcome(_status), do: :still_pending

  defp log_failure(label, reason) do
    Logger.warning("[Fund] reconcile: #{label} failed: #{inspect(reason)}")
    :errors
  end
end
