defmodule Systems.Fund.ReconcilePayoutsTest do
  use Core.DataCase, async: true
  import Mox
  import Ecto.Query

  alias Core.Factories
  alias Core.Repo
  alias Systems.Fund
  alias Systems.Payment
  alias Systems.Payment.ProviderMock

  setup :verify_on_exit!

  defp reconcile(opts \\ []) do
    Payment.Public.new_reconciliation_state()
    |> then(&Fund.Public.reconcile_pending_payouts(opts, &1))
    |> Map.fetch!(:summary)
  end

  setup do
    currency =
      Fund.Factories.create_currency(
        "recon_cur_#{System.unique_integer([:positive])}",
        :legal,
        "ƒ",
        2
      )

    fund =
      Fund.Factories.create_fund("recon_fund_#{System.unique_integer([:positive])}", currency)

    user = Factories.insert!(:member, %{creator: false, merchant_uid: "m_recon"})
    {:ok, fund: fund, user: user}
  end

  defp insert_payout(user, fund, amount, provider_uid, opts \\ []) do
    minutes_ago = Keyword.get(opts, :minutes_ago, 120)
    status = Keyword.get(opts, :status, :pending)

    payout =
      Factories.insert!(:payout, %{
        user: user,
        amount_cents: amount,
        currency: "eur",
        status: status,
        provider_uid: provider_uid
      })

    reward =
      Factories.insert!(:reward, %{
        user: user,
        fund: fund,
        amount: amount,
        status: :pending_payout,
        payout_id: payout.id,
        idempotence_key: "recon-#{System.unique_integer([:positive])}"
      })

    backdate(payout, minutes_ago)
    {Repo.reload!(payout), reward}
  end

  defp backdate(payout, minutes_ago) do
    ts =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.add(-minutes_ago * 60, :second)
      |> NaiveDateTime.truncate(:second)

    from(p in Fund.PayoutModel, where: p.id == ^payout.id)
    |> Repo.update_all(set: [inserted_at: ts])
  end

  test "resolves a pending payout that OPP has completed", %{user: user, fund: fund} do
    {payout, reward} = insert_payout(user, fund, 1000, "w_done")

    expect(ProviderMock, :get_withdrawal, fn "w_done" ->
      {:ok, %{uid: "w_done", status: "completed", amount: 1000}}
    end)

    assert %{scanned: 1, resolved_completed: 1} = reconcile()
    assert %{status: :completed} = Repo.reload!(payout)
    assert %{status: :paid} = Repo.reload!(reward)
  end

  test "resolves a pending payout that OPP has failed", %{user: user, fund: fund} do
    {payout, reward} = insert_payout(user, fund, 1000, "w_failed")

    expect(ProviderMock, :get_withdrawal, fn "w_failed" ->
      {:ok, %{uid: "w_failed", status: "failed", amount: 1000}}
    end)

    assert %{scanned: 1, resolved_failed: 1} = reconcile()
    assert %{status: :failed} = Repo.reload!(payout)
    # Charge already moved funds, so rewards stay locked for reconciliation.
    assert %{status: :pending_payout} = Repo.reload!(reward)
  end

  test "leaves a payout that OPP is still processing", %{user: user, fund: fund} do
    {payout, _reward} = insert_payout(user, fund, 1000, "w_inflight")

    expect(ProviderMock, :get_withdrawal, fn "w_inflight" ->
      {:ok, %{uid: "w_inflight", status: "pending", amount: 1000}}
    end)

    assert %{scanned: 1, still_pending: 1} = reconcile()
    assert %{status: :pending} = Repo.reload!(payout)
  end

  test "reports a pending payout with no provider_uid as unresolvable, without calling OPP",
       %{user: user, fund: fund} do
    {payout, _reward} = insert_payout(user, fund, 1000, nil)
    # No ProviderMock stub: Mox would raise if get_withdrawal were called.

    assert %{scanned: 1, unresolvable: 1} = reconcile()
    assert %{status: :pending} = Repo.reload!(payout)
  end

  test "skips payouts newer than the min age", %{user: user, fund: fund} do
    insert_payout(user, fund, 1000, "w_fresh", minutes_ago: 5)
    # default min_age is 60 minutes; no OPP call expected.

    assert %{scanned: 0} = reconcile()
  end

  test "counts an OPP query error and leaves the payout pending", %{user: user, fund: fund} do
    {payout, _reward} = insert_payout(user, fund, 1000, "w_err")

    expect(ProviderMock, :get_withdrawal, fn "w_err" ->
      {:error, %Systems.Payment.Error{code: :http_error, message: "boom"}}
    end)

    assert %{scanned: 1, errors: 1} = reconcile()
    assert %{status: :pending} = Repo.reload!(payout)
  end

  test "opens the circuit after repeated provider failures and skips the rest",
       %{user: user, fund: fund} do
    for i <- 1..6, do: insert_payout(user, fund, 1000, "w_c#{i}")

    # Circuit opens after 5 consecutive failures, so only 5 provider calls happen;
    # the 6th payout is skipped without a call (Mox would raise on a 6th call).
    expect(ProviderMock, :get_withdrawal, 5, fn _uid ->
      {:error, %Systems.Payment.Error{code: :connection_error, message: "down"}}
    end)

    assert %{scanned: 6, errors: 5, skipped: 1} = reconcile()
  end

  test "flags a :completed payout the provider has no record of", %{user: user, fund: fund} do
    {payout, _reward} = insert_payout(user, fund, 1000, "w_gone", status: :completed)

    expect(ProviderMock, :get_withdrawal, fn "w_gone" ->
      {:error, %Systems.Payment.Error{code: :api_error, details: %{status: 404}}}
    end)

    assert %{scanned: 1, missing_at_provider: 1} = reconcile()
    assert %{status: :completed} = Repo.reload!(payout)
  end
end
