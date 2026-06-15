defmodule Systems.Budget.ReconcileTransactionsTest do
  use Core.DataCase, async: true
  import Mox
  import Ecto.Query

  alias Core.Factories
  alias Core.Repo
  alias Systems.Bookkeeping
  alias Systems.Budget
  alias Systems.Fund
  alias Systems.Payment.ProviderMock

  setup :verify_on_exit!

  defp setup_transaction(status, opts \\ []) do
    minutes_ago = Keyword.get(opts, :minutes_ago, 120)
    with_ledger? = Keyword.get(opts, :ledger, true)
    user = Factories.insert!(:member)

    fund =
      %Fund.Model{}
      |> Ecto.Changeset.change(%{name: "recon-fund-#{System.unique_integer([:positive])}"})
      |> Ecto.Changeset.put_assoc(:auth_node, Factories.build(:auth_node))
      |> Ecto.Changeset.put_assoc(
        :available,
        Bookkeeping.AccountModel.create({:fund, Ecto.UUID.generate()})
      )
      |> Ecto.Changeset.put_assoc(
        :pending,
        Bookkeeping.AccountModel.create({:reserve, Ecto.UUID.generate()})
      )
      |> maybe_put_ledger(with_ledger?)
      |> Repo.insert!()

    uid = "provider-" <> Ecto.UUID.generate()

    {:ok, transaction} =
      %Budget.TransactionModel{}
      |> Budget.TransactionModel.changeset(%{
        transaction_id: uid,
        status: status,
        idempotence_key: Ecto.UUID.generate(),
        invoice_id: "NEXT-TEST-#{System.unique_integer([:positive])}",
        subject_count: 10
      })
      |> Ecto.Changeset.put_change(:user_id, user.id)
      |> Ecto.Changeset.put_change(:target_fund_id, fund.id)
      |> Repo.insert()

    backdate(transaction, minutes_ago)
    Repo.reload!(transaction)
  end

  defp backdate(transaction, minutes_ago) do
    ts =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.add(-minutes_ago * 60, :second)
      |> NaiveDateTime.truncate(:second)

    from(t in Budget.TransactionModel, where: t.id == ^transaction.id)
    |> Repo.update_all(set: [inserted_at: ts])
  end

  defp ensure_currency_ledger(currency) do
    case Budget.CurrencyLedgerModel.get_by_currency(currency) do
      nil -> Budget.CurrencyLedgerModel.create(currency) |> Repo.insert!()
      existing -> Repo.preload(existing, [:inbound, :outbound])
    end
  end

  defp maybe_put_ledger(changeset, false), do: changeset

  defp maybe_put_ledger(changeset, true) do
    Ecto.Changeset.put_change(changeset, :currency_ledger_id, ensure_currency_ledger(:EUR).id)
  end

  defp stub_opp_status(uid, status) do
    expect(ProviderMock, :get_transaction, fn ^uid ->
      {:ok, %{uid: uid, status: status, payment_url: nil, amount: 0}}
    end)
  end

  test "completes a pending transaction that OPP has completed" do
    transaction = setup_transaction(:pending)
    stub_opp_status(transaction.transaction_id, "completed")

    assert %{scanned: 1, resolved_completed: 1} = Budget.Public.reconcile_transactions()
    assert %{status: :completed} = Repo.reload!(transaction)
  end

  test "rescues a locally :failed transaction that OPP actually completed" do
    transaction = setup_transaction(:failed)
    stub_opp_status(transaction.transaction_id, "completed")

    assert %{scanned: 1, resolved_completed: 1} = Budget.Public.reconcile_transactions()
    assert %{status: :completed} = Repo.reload!(transaction)
  end

  test "leaves a :failed transaction that OPP confirms failed" do
    transaction = setup_transaction(:failed)
    stub_opp_status(transaction.transaction_id, "failed")

    assert %{scanned: 1, resolved_failed: 1} = Budget.Public.reconcile_transactions()
    assert %{status: :failed} = Repo.reload!(transaction)
  end

  test "fails a pending transaction that OPP has failed" do
    transaction = setup_transaction(:pending)
    stub_opp_status(transaction.transaction_id, "failed")

    assert %{scanned: 1, resolved_failed: 1} = Budget.Public.reconcile_transactions()
    assert %{status: :failed} = Repo.reload!(transaction)
  end

  test "leaves a pending transaction that OPP is still processing" do
    transaction = setup_transaction(:pending)
    stub_opp_status(transaction.transaction_id, "new")

    assert %{scanned: 1, still_pending: 1} = Budget.Public.reconcile_transactions()
    assert %{status: :pending} = Repo.reload!(transaction)
  end

  test "skips transactions newer than the min age" do
    setup_transaction(:pending, minutes_ago: 5)
    # default min_age is 60 minutes; no OPP call expected.

    assert %{scanned: 0} = Budget.Public.reconcile_transactions()
  end

  test "counts an OPP query error and leaves the transaction untouched" do
    transaction = setup_transaction(:pending)

    expect(ProviderMock, :get_transaction, fn _uid ->
      {:error, %Systems.Payment.Error{code: :http_error, message: "boom"}}
    end)

    assert %{scanned: 1, errors: 1} = Budget.Public.reconcile_transactions()
    assert %{status: :pending} = Repo.reload!(transaction)
  end

  test "tallies :errors (does not crash, does not report resolved) when the resolution raises" do
    # A fund without a currency ledger makes complete_transaction raise. A single
    # bad row must be counted as :errors, not abort the sweep or be logged as fixed.
    transaction = setup_transaction(:failed, ledger: false)
    stub_opp_status(transaction.transaction_id, "completed")

    assert %{scanned: 1, errors: 1, resolved_completed: 0} =
             Budget.Public.reconcile_transactions()

    assert %{status: :failed} = Repo.reload!(transaction)
  end
end
