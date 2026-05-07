defmodule Systems.Budget.PayInExpirationTest do
  use Core.DataCase, async: true

  alias Core.Factories
  alias Core.Repo
  alias Systems.Budget

  describe "expire_stale_pay_ins/1" do
    test "marks pending transactions older than the cutoff as failed" do
      fresh = insert_transaction!(:pending, minutes_ago: 5)
      stale = insert_transaction!(:pending, minutes_ago: 20)

      assert 1 = Budget.Public.expire_stale_pay_ins(15)

      assert %{status: :pending} = Repo.get!(Budget.TransactionModel, fresh.id)
      assert %{status: :failed} = Repo.get!(Budget.TransactionModel, stale.id)
    end

    test "leaves non-pending transactions alone" do
      completed = insert_transaction!(:completed, minutes_ago: 60)
      failed = insert_transaction!(:failed, minutes_ago: 60)

      assert 0 = Budget.Public.expire_stale_pay_ins(15)

      assert %{status: :completed} = Repo.get!(Budget.TransactionModel, completed.id)
      assert %{status: :failed} = Repo.get!(Budget.TransactionModel, failed.id)
    end

    test "returns 0 when there is nothing to expire" do
      insert_transaction!(:pending, minutes_ago: 5)
      assert 0 = Budget.Public.expire_stale_pay_ins(15)
    end
  end

  defp insert_transaction!(status, minutes_ago: minutes_ago) do
    user = Factories.insert!(:member)
    fund = Factories.insert!(:fund, %{name: "test-fund-#{System.unique_integer([:positive])}"})

    past =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.add(-minutes_ago * 60, :second)
      |> NaiveDateTime.truncate(:second)

    {:ok, transaction} =
      %Budget.TransactionModel{}
      |> Budget.TransactionModel.changeset(%{
        transaction_id: Ecto.UUID.generate(),
        status: status,
        idempotence_key: Ecto.UUID.generate(),
        invoice_id: "NEXT-TEST-#{System.unique_integer([:positive])}",
        subject_count: 10
      })
      |> Ecto.Changeset.put_change(:user_id, user.id)
      |> Ecto.Changeset.put_change(:target_fund_id, fund.id)
      |> Ecto.Changeset.put_change(:inserted_at, past)
      |> Ecto.Changeset.put_change(:updated_at, past)
      |> Repo.insert()

    transaction
  end
end
