defmodule Systems.Fund.ReconcilePayoutsTest do
  use Core.DataCase, async: true
  import Mox
  import Ecto.Query

  alias Core.Factories
  alias Core.Repo
  alias Systems.Fund
  alias Systems.Payment.ProviderMock

  setup :verify_on_exit!

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

    payout =
      Repo.insert!(%Fund.PayoutModel{
        user_id: user.id,
        amount_cents: amount,
        currency: "eur",
        status: :pending,
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

    assert %{scanned: 1, resolved_completed: 1} = Fund.Public.reconcile_pending_payouts()
    assert %{status: :completed} = Repo.reload!(payout)
    assert %{status: :paid} = Repo.reload!(reward)
  end

  test "resolves a pending payout that OPP has failed", %{user: user, fund: fund} do
    {payout, reward} = insert_payout(user, fund, 1000, "w_failed")

    expect(ProviderMock, :get_withdrawal, fn "w_failed" ->
      {:ok, %{uid: "w_failed", status: "failed", amount: 1000}}
    end)

    assert %{scanned: 1, resolved_failed: 1} = Fund.Public.reconcile_pending_payouts()
    assert %{status: :failed} = Repo.reload!(payout)
    # Charge already moved funds, so rewards stay locked for reconciliation.
    assert %{status: :pending_payout} = Repo.reload!(reward)
  end

  test "leaves a payout that OPP is still processing", %{user: user, fund: fund} do
    {payout, _reward} = insert_payout(user, fund, 1000, "w_inflight")

    expect(ProviderMock, :get_withdrawal, fn "w_inflight" ->
      {:ok, %{uid: "w_inflight", status: "pending", amount: 1000}}
    end)

    assert %{scanned: 1, still_pending: 1} = Fund.Public.reconcile_pending_payouts()
    assert %{status: :pending} = Repo.reload!(payout)
  end

  test "reports a pending payout with no provider_uid as unresolvable, without calling OPP",
       %{user: user, fund: fund} do
    {payout, _reward} = insert_payout(user, fund, 1000, nil)
    # No ProviderMock stub: Mox would raise if get_withdrawal were called.

    assert %{scanned: 1, unresolvable: 1} = Fund.Public.reconcile_pending_payouts()
    assert %{status: :pending} = Repo.reload!(payout)
  end

  test "skips payouts newer than the min age", %{user: user, fund: fund} do
    insert_payout(user, fund, 1000, "w_fresh", minutes_ago: 5)
    # default min_age is 60 minutes; no OPP call expected.

    assert %{scanned: 0} = Fund.Public.reconcile_pending_payouts()
  end

  test "counts an OPP query error and leaves the payout pending", %{user: user, fund: fund} do
    {payout, _reward} = insert_payout(user, fund, 1000, "w_err")

    expect(ProviderMock, :get_withdrawal, fn "w_err" ->
      {:error, %Systems.Payment.Error{code: :http_error, message: "boom"}}
    end)

    assert %{scanned: 1, errors: 1} = Fund.Public.reconcile_pending_payouts()
    assert %{status: :pending} = Repo.reload!(payout)
  end
end
