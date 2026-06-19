defmodule Systems.Budget.CreatePayInTest do
  @moduledoc """
  Unit coverage for `Budget.Public.create_pay_in/3`.

  Mirrors two scenarios that previously lived in
  `test/e2e/fund_assignment.spec.ts` as Playwright E2E tests:

    * "researcher can add a second transaction on the same assignment"
      (UC-OPP-01: second transaction)
    * "researcher sees failed transaction when payment is rejected and
      can retry" (UC-OPP-01.A1)

  These are state-machine / business-logic concerns, not user-journey
  concerns — per `test/features/CLAUDE.md` they belong here, not in a
  Wallaby feature test.
  """

  use Core.DataCase, async: false
  import Mox

  alias Core.Factories
  alias Core.Repo
  alias Systems.Budget
  alias Systems.Fund
  alias Systems.Payment.ProviderMock

  setup :set_mox_from_context
  setup :verify_on_exit!

  describe "create_pay_in/3" do
    test "creates a fresh transaction on each call against the same assignment (UC-OPP-01: second transaction)" do
      %{assignment: assignment, user: user} = setup_assignment()

      stub_provider_create_transaction()

      {:ok, %{transaction: t1}} = Budget.Public.create_pay_in(assignment, user, 10)
      {:ok, %{transaction: t2}} = Budget.Public.create_pay_in(assignment, user, 10)

      # Two distinct rows
      assert t1.id != t2.id

      # Each gets its own provider uid + idempotence_key, otherwise the
      # second insert would collide on the `idempotence_key` unique index
      # and the test would have failed at the second `create_pay_in/3`.
      assert t1.transaction_id != t2.transaction_id
      assert t1.idempotence_key != t2.idempotence_key

      # Both rows persisted, both `:pending`.
      assert [%{status: :pending}, %{status: :pending}] =
               Repo.all(Budget.TransactionModel) |> Enum.sort_by(& &1.id)
    end

    test "can create a fresh transaction after a previous one was marked :failed (UC-OPP-01.A1: retry)" do
      %{assignment: assignment, user: user} = setup_assignment()

      stub_provider_create_transaction()

      # First transaction → fail it (simulates the payment-failed webhook).
      {:ok, %{transaction: failed}} = Budget.Public.create_pay_in(assignment, user, 10)
      {:ok, _} = Budget.Public.fail_transaction(failed.transaction_id)

      # Retry — the researcher clicks "Confirm" again on a fresh BudgetForm.
      {:ok, %{transaction: retry}} = Budget.Public.create_pay_in(assignment, user, 10)

      assert retry.id != failed.id
      assert retry.status == :pending
      assert retry.transaction_id != failed.transaction_id

      assert %{status: :failed} = Repo.get!(Budget.TransactionModel, failed.id)
      assert %{status: :pending} = Repo.get!(Budget.TransactionModel, retry.id)
    end
  end

  defp setup_assignment do
    ensure_currency_ledger(:EUR)

    user =
      Factories.insert!(:member, %{
        confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        creator: true,
        merchant_uid: "m_create_pay_in"
      })

    currency = Factories.insert!(:currency, %{name: "eur_pay_in"})
    fund = Fund.Factories.create_fund("pay_in_fund", currency)

    info = Factories.insert!(:assignment_info, %{subject_count: 10, subject_reward: 500})

    assignment =
      Factories.insert!(:assignment, %{
        info: info,
        fund: fund,
        status: :online,
        special: :questionnaire
      })

    assignment = Repo.preload(assignment, [info: [], fund: [:currency]], force: true)

    %{assignment: assignment, user: user}
  end

  defp ensure_currency_ledger(currency) do
    case Budget.CurrencyLedgerModel.get_by_currency(currency) do
      nil ->
        Factories.insert!(:currency_ledger, %{currency: currency})

      existing ->
        existing
    end
  end

  defp stub_provider_create_transaction do
    stub(ProviderMock, :get_merchant, fn _uid ->
      {:ok,
       %{uid: "m_create_pay_in", status: "active", kyc_level: 100, compliance_status: "verified"}}
    end)

    stub(ProviderMock, :create_transaction, fn _request ->
      uid = Ecto.UUID.generate()

      {:ok, %{uid: uid, payment_url: "/payment/local/#{uid}", status: "created", amount: 5000}}
    end)
  end
end
