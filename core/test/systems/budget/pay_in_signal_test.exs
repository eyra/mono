defmodule Systems.Budget.PayInSignalTest do
  use Core.DataCase, async: false

  alias Core.Factories
  alias Core.Repo
  alias CoreWeb.Endpoint
  alias Systems.Assignment
  alias Systems.Bookkeeping
  alias Systems.Budget
  alias Systems.Fund

  setup do
    Frameworks.Signal.TestHelper.isolate_signals(except: [Systems.Observatory.Switch])
    :ok
  end

  describe "expire_stale_pay_ins/1 signal broadcast" do
    test "broadcasts {:page, Assignment.ContentPage} for each fund with expired rows" do
      %{assignment: assignment, transaction: _transaction} =
        setup_stale_transaction()

      topic = "signal:#{Systems.Assignment.ContentPage}:#{assignment.id}"
      Endpoint.subscribe(topic)

      assert 1 = Budget.Public.expire_stale_pay_ins(15)

      assert_receive %Phoenix.Socket.Broadcast{
        topic: ^topic,
        event: "observation",
        payload: {Systems.Assignment.ContentPage, %{id: _, model: %Assignment.Model{}}}
      }
    end
  end

  describe "complete_transaction/1 signal broadcast" do
    test "broadcasts after flipping a :failed row back to :completed (race recovery)" do
      %{assignment: assignment, transaction: transaction} =
        setup_transaction(:failed)

      topic = "signal:#{Systems.Assignment.ContentPage}:#{assignment.id}"
      Endpoint.subscribe(topic)

      assert {:ok, _} = Budget.Public.complete_transaction(transaction.transaction_id)

      assert_receive %Phoenix.Socket.Broadcast{
        topic: ^topic,
        event: "observation",
        payload: {Systems.Assignment.ContentPage, %{id: _}}
      }
    end
  end

  describe "fail_transaction/1 signal broadcast" do
    test "broadcasts after marking a :pending row failed via webhook" do
      %{assignment: assignment, transaction: transaction} =
        setup_transaction(:pending)

      topic = "signal:#{Systems.Assignment.ContentPage}:#{assignment.id}"
      Endpoint.subscribe(topic)

      assert {:ok, _} = Budget.Public.fail_transaction(transaction.transaction_id)

      assert_receive %Phoenix.Socket.Broadcast{
        topic: ^topic,
        event: "observation",
        payload: {Systems.Assignment.ContentPage, %{id: _}}
      }
    end
  end

  defp setup_stale_transaction do
    %{assignment: assignment, fund: fund, user: user} = setup_assignment()

    past =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.add(-20 * 60, :second)
      |> NaiveDateTime.truncate(:second)

    {:ok, transaction} =
      %Budget.TransactionModel{}
      |> Budget.TransactionModel.changeset(%{
        transaction_id: "provider-" <> Ecto.UUID.generate(),
        status: :pending,
        idempotence_key: Ecto.UUID.generate(),
        invoice_id: "NEXT-TEST-#{System.unique_integer([:positive])}",
        subject_count: 10
      })
      |> Ecto.Changeset.put_change(:user_id, user.id)
      |> Ecto.Changeset.put_change(:target_fund_id, fund.id)
      |> Ecto.Changeset.put_change(:inserted_at, past)
      |> Ecto.Changeset.put_change(:updated_at, past)
      |> Repo.insert()

    %{assignment: assignment, transaction: transaction, fund: fund, user: user}
  end

  defp setup_transaction(status) do
    %{assignment: assignment, fund: fund, user: user} = setup_assignment()

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

    %{assignment: assignment, transaction: transaction, fund: fund, user: user}
  end

  defp setup_assignment do
    currency_ledger = ensure_currency_ledger(:EUR)
    user = Factories.insert!(:member)

    fund =
      %Fund.Model{}
      |> Ecto.Changeset.change(%{name: "test-fund-#{System.unique_integer([:positive])}"})
      |> Ecto.Changeset.put_assoc(:auth_node, Factories.build(:auth_node))
      |> Ecto.Changeset.put_assoc(
        :fund,
        Bookkeeping.AccountModel.create({:fund, Ecto.UUID.generate()})
      )
      |> Ecto.Changeset.put_assoc(
        :reserve,
        Bookkeeping.AccountModel.create({:reserve, Ecto.UUID.generate()})
      )
      |> Ecto.Changeset.put_change(:currency_ledger_id, currency_ledger.id)
      |> Repo.insert!()

    assignment =
      Factories.insert!(:assignment, %{
        fund: fund
      })

    %{assignment: assignment, fund: fund, user: user}
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
