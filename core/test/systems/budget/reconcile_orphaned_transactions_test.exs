defmodule Systems.Budget.ReconcileOrphanedTransactionsTest do
  @moduledoc """
  Provider→local pass for pay-ins: given the transactions the provider holds,
  flag the ones with no local row — the restore-orphan case.
  """
  use Core.DataCase, async: true
  import Mox

  alias Core.Factories
  alias Core.Repo
  alias Systems.Bookkeeping
  alias Systems.Budget
  alias Systems.Fund
  alias Systems.Payment
  alias Systems.Payment.ProviderMock

  setup :verify_on_exit!

  defp state, do: Payment.Public.new_reconciliation_state()

  defp local_transaction(idempotence_key) do
    currency_ledger =
      case Budget.CurrencyLedgerModel.get_by_currency(:EUR) do
        nil -> Budget.CurrencyLedgerModel.create(:EUR) |> Repo.insert!()
        existing -> Repo.preload(existing, [:inbound, :outbound])
      end

    fund =
      %Fund.Model{}
      |> Ecto.Changeset.change(%{name: "o-fund-#{System.unique_integer([:positive])}"})
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

    %Budget.TransactionModel{}
    |> Budget.TransactionModel.changeset(%{
      transaction_id: "tra_#{System.unique_integer([:positive])}",
      status: :pending,
      idempotence_key: idempotence_key,
      invoice_id: "NEXT-O-#{System.unique_integer([:positive])}",
      subject_count: 10
    })
    |> Ecto.Changeset.put_change(:user_id, Factories.insert!(:member).id)
    |> Ecto.Changeset.put_change(:target_fund_id, fund.id)
    |> Repo.insert!()
  end

  defp provider_transaction(reference, opts \\ []) do
    %{
      uid: Keyword.get(opts, :uid, "tra_#{System.unique_integer([:positive])}"),
      status: :completed,
      raw_status: "completed",
      payment_url: nil,
      amount: 1440,
      reference: reference,
      created: Keyword.get(opts, :created, hours_ago(24))
    }
  end

  defp hours_ago(hours), do: DateTime.add(DateTime.utc_now(), -hours * 60 * 60, :second)

  defp run(transactions, opts \\ []) do
    expect(ProviderMock, :list_recent_transactions, fn _since -> {:ok, transactions} end)
    Budget.Public.reconcile_orphaned_transactions(opts, state())
  end

  describe "orphan detection" do
    test "flags a transaction whose pay-in has no local row" do
      %{summary: summary, findings: findings} =
        run([provider_transaction("pay_in:fund=1:#{Ecto.UUID.generate()}", uid: "tra_lost")])

      assert summary.missing_locally == 1
      assert summary.scanned == 1

      assert [
               %{
                 outcome: :missing_locally,
                 subject_type: :transaction,
                 subject_id: nil,
                 provider_uid: "tra_lost"
               }
             ] = findings
    end

    test "a pay-in that does exist locally is verified, not flagged" do
      key = "pay_in:fund=1:#{Ecto.UUID.generate()}"
      local_transaction(key)

      %{summary: summary, findings: findings} = run([provider_transaction(key)])

      assert summary.verified == 1
      assert summary.missing_locally == 0
      assert findings == []
    end

    test "records the amount on the finding" do
      %{findings: [%{details: details}]} =
        run([provider_transaction("pay_in:fund=1:#{Ecto.UUID.generate()}")])

      assert details.amount == 1440
    end

    test "matches on idempotence_key, not invoice_id" do
      # A restore rewinds the invoice sequence, so a local row sharing the
      # orphan's invoice_id must not make the orphan look present.
      local = local_transaction("pay_in:fund=1:#{Ecto.UUID.generate()}")
      orphan = provider_transaction("pay_in:fund=1:#{Ecto.UUID.generate()}")

      %{summary: summary} = run([orphan])

      assert summary.missing_locally == 1
      assert Repo.reload!(local).idempotence_key != orphan.reference
    end
  end

  describe "transactions predating the reference metadata" do
    test "are reported as unresolvable rather than passed over" do
      %{summary: summary, findings: findings} =
        run([provider_transaction(nil, uid: "tra_old")])

      assert summary.unresolvable == 1
      assert summary.missing_locally == 0
      assert summary.verified == 0

      assert [%{outcome: :unresolvable, provider_uid: "tra_old", details: %{reason: reason}}] =
               findings

      assert reason =~ "no reference"
    end

    test "do not stop a referenced orphan in the same batch from being flagged" do
      %{summary: summary} =
        run([
          provider_transaction(nil),
          provider_transaction("pay_in:fund=1:#{Ecto.UUID.generate()}")
        ])

      assert summary.unresolvable == 1
      assert summary.missing_locally == 1
      assert summary.scanned == 2
    end
  end

  describe "windowing" do
    test "a transaction younger than min_age is left alone" do
      recent = provider_transaction("pay_in:fund=1:x", created: hours_ago(0))

      %{summary: summary} = run([recent])

      assert summary.scanned == 0
      assert summary.missing_locally == 0
    end

    test "a transaction with no creation timestamp is still scanned" do
      %{summary: summary} =
        run([provider_transaction("pay_in:fund=1:#{Ecto.UUID.generate()}", created: nil)])

      assert summary.missing_locally == 1
    end

    test "min_age_minutes is overridable" do
      recent =
        provider_transaction("pay_in:fund=1:#{Ecto.UUID.generate()}", created: hours_ago(1))

      %{summary: summary} = run([recent], min_age_minutes: 0)

      assert summary.missing_locally == 1
    end
  end

  describe "provider failures" do
    test "a failed listing is tallied, not silently skipped" do
      expect(ProviderMock, :list_recent_transactions, fn _since ->
        {:error, %Payment.Error{code: :api_error, message: "boom"}}
      end)

      %{summary: summary, findings: findings} =
        Budget.Public.reconcile_orphaned_transactions([], state())

      assert summary.errors == 1
      assert [%{outcome: :errors, subject_type: :transaction, subject_id: nil}] = findings
    end

    test "an open circuit skips the pass rather than reporting no orphans" do
      open_circuit =
        Enum.reduce(1..5, state(), fn _i, acc ->
          Payment.ReconciliationState.record_failure(acc)
        end)

      %{summary: summary} = Budget.Public.reconcile_orphaned_transactions([], open_circuit)

      assert summary.skipped == 1
      assert summary.missing_locally == 0
    end
  end
end
