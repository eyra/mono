defmodule Systems.Payment.ReconciliationWorkerTest do
  @moduledoc """
  Integration: one worker run reconciles both a stuck pay-in (Budget) and a
  stuck payout (Fund) against OPP. The per-type resolution rules are covered by
  ReconcileTransactionsTest / ReconcilePayoutsTest; here we assert the worker
  delegates to both and returns :ok.
  """
  use Core.DataCase, async: true
  import Mox
  import Ecto.Query

  alias Core.Factories
  alias Core.Repo
  alias Systems.Bookkeeping
  alias Systems.Budget
  alias Systems.Fund
  alias Systems.Payment.ProviderMock
  alias Systems.Payment.ReconciliationFindingModel
  alias Systems.Payment.ReconciliationRunModel
  alias Systems.Payment.ReconciliationWorker

  setup :verify_on_exit!

  defp backdate(queryable, id, minutes_ago) do
    ts =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.add(-minutes_ago * 60, :second)
      |> NaiveDateTime.truncate(:second)

    from(r in queryable, where: r.id == ^id) |> Repo.update_all(set: [inserted_at: ts])
  end

  defp stuck_payout do
    currency =
      Fund.Factories.create_currency(
        "w_cur_#{System.unique_integer([:positive])}",
        :legal,
        "ƒ",
        2
      )

    fund = Fund.Factories.create_fund("w_fund_#{System.unique_integer([:positive])}", currency)
    user = Factories.insert!(:member, %{creator: false, merchant_uid: "m_w"})

    payout =
      Repo.insert!(%Fund.PayoutModel{
        user_id: user.id,
        amount_cents: 1000,
        currency: "eur",
        status: :pending,
        provider_uid: "w_payout"
      })

    Factories.insert!(:reward, %{
      user: user,
      fund: fund,
      amount: 1000,
      status: :pending_payout,
      payout_id: payout.id,
      idempotence_key: "w-#{System.unique_integer([:positive])}"
    })

    backdate(Fund.PayoutModel, payout.id, 120)
    payout
  end

  defp stuck_transaction do
    currency_ledger =
      case Budget.CurrencyLedgerModel.get_by_currency(:EUR) do
        nil -> Budget.CurrencyLedgerModel.create(:EUR) |> Repo.insert!()
        existing -> Repo.preload(existing, [:inbound, :outbound])
      end

    user = Factories.insert!(:member)

    fund =
      %Fund.Model{}
      |> Ecto.Changeset.change(%{name: "w-fund-#{System.unique_integer([:positive])}"})
      |> Ecto.Changeset.put_assoc(:auth_node, Factories.build(:auth_node))
      |> Ecto.Changeset.put_assoc(
        :available,
        Bookkeeping.AccountModel.create({:fund, Ecto.UUID.generate()})
      )
      |> Ecto.Changeset.put_assoc(
        :pending,
        Bookkeeping.AccountModel.create({:reserve, Ecto.UUID.generate()})
      )
      |> Ecto.Changeset.put_change(:currency_ledger_id, currency_ledger.id)
      |> Repo.insert!()

    {:ok, transaction} =
      %Budget.TransactionModel{}
      |> Budget.TransactionModel.changeset(%{
        transaction_id: "tx_payin",
        status: :pending,
        idempotence_key: Ecto.UUID.generate(),
        invoice_id: "NEXT-W-#{System.unique_integer([:positive])}",
        subject_count: 10
      })
      |> Ecto.Changeset.put_change(:user_id, user.id)
      |> Ecto.Changeset.put_change(:target_fund_id, fund.id)
      |> Repo.insert()

    backdate(Budget.TransactionModel, transaction.id, 120)
    transaction
  end

  test "reconciles both a stuck payout and a stuck pay-in in one run" do
    payout = stuck_payout()
    transaction = stuck_transaction()

    expect(ProviderMock, :get_withdrawal, fn "w_payout" ->
      {:ok, %{uid: "w_payout", status: "completed", amount: 1000}}
    end)

    expect(ProviderMock, :get_transaction, fn "tx_payin" ->
      {:ok, %{uid: "tx_payin", status: "completed", payment_url: nil, amount: 0}}
    end)

    assert :ok = ReconciliationWorker.perform(%Oban.Job{args: %{}})

    assert %{status: :completed} = Repo.reload!(payout)
    assert %{status: :completed} = Repo.reload!(transaction)
  end

  test "records the run and its findings in the database" do
    payout = stuck_payout()
    transaction = stuck_transaction()

    expect(ProviderMock, :get_withdrawal, fn "w_payout" ->
      {:ok, %{uid: "w_payout", status: "completed", amount: 1000}}
    end)

    expect(ProviderMock, :get_transaction, fn "tx_payin" ->
      {:ok, %{uid: "tx_payin", status: "completed", payment_url: nil, amount: 0}}
    end)

    assert :ok = ReconciliationWorker.perform(%Oban.Job{args: %{}})

    run = Repo.one!(ReconciliationRunModel)
    assert run.run_type == :cron
    assert run.finished_at != nil
    assert run.scanned == 2
    assert run.resolved_completed == 2

    findings = Repo.all(ReconciliationFindingModel)
    assert length(findings) == 2
    assert Enum.all?(findings, &(&1.outcome == :resolved_completed))
    assert Enum.all?(findings, &(&1.reconciliation_run_id == run.id))

    assert MapSet.new(findings, & &1.subject_type) == MapSet.new([:payout, :transaction])
    assert MapSet.new(findings, & &1.subject_id) == MapSet.new([payout.id, transaction.id])
  end
end
