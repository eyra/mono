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
  end

  defp setup_transaction(status: status) do
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
        subject_count: 10
      })
      |> Ecto.Changeset.put_change(:user_id, user.id)
      |> Ecto.Changeset.put_change(:target_fund_id, fund.id)
      |> Repo.insert()

    %{transaction: transaction, fund: fund, user: user}
  end

  defp ensure_currency_ledger(currency) do
    case Budget.CurrencyLedgerModel.get_by_currency(currency) do
      nil ->
        Budget.CurrencyLedgerModel.create(currency) |> Repo.insert!()

      existing ->
        existing |> Repo.preload([:inbound, :outbound])
    end
  end
end
