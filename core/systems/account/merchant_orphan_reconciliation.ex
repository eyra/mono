defmodule Systems.Account.MerchantOrphanReconciliation do
  @moduledoc """
  Provider→local reconciliation for merchants: lists the merchants the provider
  created inside the window and flags any whose uid no user carries.

  This is the restore case that blocks a payout rather than losing one. A
  merchant is created at the provider first and its uid written to
  `users.merchant_uid` after; a restore that rolls back that write leaves an
  account at the provider — possibly a KYC-verified one, with a bank account
  attached — that we can no longer reach. The participant sees no payout option
  and a fresh merchant cannot be created, because the provider rejects the
  duplicate email.

  Matching is on the merchant uid alone. The merchant carries no local
  identifier that survives a restore: `metadata.user_id` is a serial the restore
  rewinds, and the email lives on the merchant's contacts rather than the object
  itself. So a finding names the merchant uid and leaves identifying the person
  to whoever resolves it, via the provider's own dashboard.

  Detection only, like its siblings — binding a user to the wrong merchant would
  send their payout to a stranger's bank account, which is worse than the gap it
  would be trying to close. Driven by `Systems.Payment.ReconciliationWorker`.
  """
  import Ecto.Query

  require Logger

  alias Core.Repo
  alias Systems.Account
  alias Systems.Payment
  alias Systems.Payment.OrphanScan
  alias Systems.Payment.ReconciliationState, as: State

  @doc """
  Scans provider merchants created in the `[max_age_days, min_age_minutes]`
  window, returning the updated state.
  """
  def run(opts, %State{} = state) do
    {oldest, newest} = Payment.Public.reconciliation_scan_window(opts)

    {merchants, state} = list_recent_merchants(state, oldest)

    merchants
    |> Enum.filter(&OrphanScan.settled?(&1, newest))
    |> Enum.reject(&platform_merchant?/1)
    |> check_against_local(state)
  end

  defp list_recent_merchants(state, oldest) do
    state
    |> Payment.Public.reconcile_list_recent_merchants(oldest)
    |> OrphanScan.take_listing(:merchant, :merchant)
  end

  # The platform merchant holds the float and deliberately has no user row, so
  # it is not an orphan — it would otherwise be flagged on every single run.
  defp platform_merchant?(%{uid: uid}), do: uid == Payment.Public.platform_merchant_uid()

  defp check_against_local(merchants, state) do
    known = known_merchant_uids(merchants)
    Enum.reduce(merchants, state, &check_one(&1, known, &2))
  end

  defp known_merchant_uids(merchants) do
    case Enum.map(merchants, & &1.uid) do
      [] -> MapSet.new()
      uids -> uids |> query_merchant_uids() |> MapSet.new()
    end
  end

  defp query_merchant_uids(uids) do
    from(u in Account.User, where: u.merchant_uid in ^uids, select: u.merchant_uid)
    |> Repo.all()
  end

  defp check_one(%{uid: uid} = merchant, known, state) do
    if MapSet.member?(known, uid) do
      State.tally(state, :verified)
    else
      flag(merchant, state)
    end
  end

  # Since the match deliberately cannot identify the person, the compliance
  # fields are the triage signal: an empty shell needs no action, while a
  # verified merchant with a bank account attached is urgent and unrecoverable
  # without help. `overview_url` is the provider's own page for the account, so
  # whoever picks the finding up has somewhere to start.
  defp flag(
         %{
           uid: uid,
           status: status,
           kyc_level: kyc_level,
           compliance_status: compliance_status,
           overview_url: overview_url
         } = merchant,
         state
       ) do
    Logger.error(
      "[Account] orphan scan: merchant #{uid} (status=#{status} kyc_level=#{kyc_level} " <>
        "compliance=#{compliance_status}) is not recorded on any user — the participant " <>
        "cannot be paid out and cannot re-register, manual review"
    )

    OrphanScan.record(
      state,
      :missing_locally,
      :merchant,
      merchant,
      %{
        status: status,
        kyc_level: kyc_level,
        compliance_status: compliance_status,
        overview_url: overview_url
      },
      :merchant
    )
  end
end
