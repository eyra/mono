defmodule Systems.Budget.CompleteTransactionTest do
  use Core.DataCase, async: true

  alias Core.Factories
  alias Core.Repo
  alias Systems.Bookkeeping
  alias Systems.Budget
  alias Systems.Fund

  describe "complete_transaction/1" do
    test "completes a :failed transaction when OPP webhook arrives after local expiry" do
      %{transaction: transaction} = setup_transaction(status: :failed)

      assert {:ok, %{transaction: %{status: :completed}}} =
               Budget.Public.complete_transaction(transaction.transaction_id)

      assert %{status: :completed} =
               Repo.get!(Budget.TransactionModel, transaction.id)
    end

    test "still completes a :pending transaction via the normal path" do
      %{transaction: transaction} = setup_transaction(status: :pending)

      assert {:ok, %{transaction: %{status: :completed}}} =
               Budget.Public.complete_transaction(transaction.transaction_id)
    end

    test "refuses a transaction that is already :completed" do
      %{transaction: transaction} = setup_transaction(status: :completed)

      assert {:error, "Transaction already completed"} =
               Budget.Public.complete_transaction(transaction.transaction_id)
    end

    test "credits the fund the base amount and books the partner fee to the ledger margin" do
      # total_amount is base (5000) + partner fee (500).
      %{transaction: transaction, fund: fund, currency_ledger: ledger} =
        setup_transaction(status: :pending, total_amount: 5500, partner_fee: 500)

      {:ok, _} = Budget.Public.complete_transaction(transaction.transaction_id)

      assert available_credit(fund) == 5000
      assert margin_credit(ledger) == 500
    end

    test "credits the paid base even after the assignment reward changed since pay-in" do
      %{transaction: transaction, fund: fund} =
        setup_transaction(status: :pending, total_amount: 5500, partner_fee: 500)

      # A lower live reward must not change the booking: 10 x 100 = 1000 would be
      # booked if completion re-derived from the reward instead of the paid amount.
      info = Factories.insert!(:assignment_info, %{subject_count: 10, subject_reward: 100})
      Factories.insert!(:assignment, %{info: info, fund: fund, status: :online})

      {:ok, _} = Budget.Public.complete_transaction(transaction.transaction_id)

      assert available_credit(fund) == 5000
    end
  end

  defp available_credit(%Fund.Model{available: account}) do
    %{credit: credit} = Bookkeeping.Public.balance(account)
    credit
  end

  defp margin_credit(%Budget.CurrencyLedgerModel{margin: margin}) do
    %{credit: credit} = Bookkeeping.Public.balance(margin)
    credit
  end

  defp setup_transaction(opts) do
    status = Keyword.fetch!(opts, :status)
    total_amount = Keyword.get(opts, :total_amount, 0)
    partner_fee = Keyword.get(opts, :partner_fee, 0)
    currency_ledger = ensure_currency_ledger(:EUR)
    user = Factories.insert!(:member)

    fund =
      %Fund.Model{}
      |> Ecto.Changeset.change(%{name: "test-fund-#{System.unique_integer([:positive])}"})
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
        transaction_id: "provider-" <> Ecto.UUID.generate(),
        status: status,
        idempotence_key: Ecto.UUID.generate(),
        invoice_id: "NEXT-TEST-#{System.unique_integer([:positive])}",
        subject_count: 10,
        total_amount: total_amount,
        partner_fee: partner_fee
      })
      |> Ecto.Changeset.put_change(:user_id, user.id)
      |> Ecto.Changeset.put_change(:target_fund_id, fund.id)
      |> Repo.insert()

    %{transaction: transaction, fund: fund, user: user, currency_ledger: currency_ledger}
  end

  defp ensure_currency_ledger(currency) do
    case Budget.CurrencyLedgerModel.get_by_currency(currency) do
      nil ->
        Budget.CurrencyLedgerModel.create(currency) |> Repo.insert!()

      existing ->
        existing |> Repo.preload([:inbound, :outbound, :margin])
    end
  end
end
