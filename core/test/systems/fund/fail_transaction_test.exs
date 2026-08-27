defmodule Systems.Fund.FailTransactionTest do
  use Core.DataCase, async: true

  import ExUnit.CaptureLog

  alias Core.Factories
  alias Core.Repo
  alias Systems.Fund

  describe "fail_transaction/1" do
    test "fails a :pending transaction via the normal path" do
      transaction = insert_transaction(:pending)

      assert {:ok, %{status: :failed}} =
               Fund.Public.fail_transaction(transaction.transaction_id)
    end

    test "refuses a late 'failed' webhook on an already-:completed transaction" do
      transaction = insert_transaction(:completed)

      log =
        capture_log(fn ->
          assert {:error, :already_completed} =
                   Fund.Public.fail_transaction(transaction.transaction_id)
        end)

      assert log =~ "refusing late 'failed' for already-completed transaction"

      # The fund stays credited, so the status must not contradict it by flipping to :failed.
      assert %{status: :completed} = Repo.get!(Fund.TransactionModel, transaction.id)
    end
  end

  defp insert_transaction(status) do
    unique = System.unique_integer([:positive])
    user = Factories.insert!(:member)
    currency = Fund.Factories.create_currency("fail_tx_#{unique}", :legal, "€", 2)
    fund = Fund.Factories.create_fund("fail_tx_fund_#{unique}", currency)

    {:ok, transaction} =
      %Fund.TransactionModel{}
      |> Fund.TransactionModel.changeset(%{
        transaction_id: "provider-" <> Ecto.UUID.generate(),
        status: status,
        idempotence_key: Ecto.UUID.generate(),
        invoice_id: "NEXT-TEST-#{unique}",
        subject_count: 10,
        total_amount: 5000
      })
      |> Ecto.Changeset.put_change(:user_id, user.id)
      |> Ecto.Changeset.put_change(:target_fund_id, fund.id)
      |> Repo.insert()

    transaction
  end
end
