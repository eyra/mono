defmodule Systems.Fund.CreatePayInTest do
  @moduledoc """
  Unit coverage for `Fund.Public.create_pay_in/3`.

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

  use Mica.DataCase, async: false
  import Mox

  alias Mica.Factories
  alias Mica.Repo
  alias Systems.Assignment
  alias Systems.Fund
  alias Systems.Payment.ProviderMock

  setup :set_mox_from_context
  setup :verify_on_exit!

  describe "create_pay_in/3" do
    test "creates a fresh transaction on each call against the same assignment (UC-OPP-01: second transaction)" do
      %{assignment: assignment, user: user} = setup_assignment()

      stub_provider_create_transaction()

      {:ok, %{transaction: t1}} =
        Fund.Public.create_pay_in(assignment, user, %{
          "subject_count" => 10,
          "subject_reward" => 500,
          "aim_of_study" => "Ten-participant test with a valid aim-of-study text."
        })

      # The researcher comes back from the payment page to a freshly loaded
      # assignment before opening the form again.
      {:ok, %{transaction: t2}} =
        Fund.Public.create_pay_in(reload(assignment), user, %{
          "subject_count" => 10,
          "subject_reward" => 500,
          "aim_of_study" => "Ten-participant test with a valid aim-of-study text."
        })

      # Two distinct rows
      assert t1.id != t2.id

      # Each gets its own provider uid + idempotence_key, otherwise the
      # second insert would collide on the `idempotence_key` unique index
      # and the test would have failed at the second `create_pay_in/3`.
      assert t1.transaction_id != t2.transaction_id
      assert t1.idempotence_key != t2.idempotence_key

      # Both rows persisted, both `:pending`.
      assert [%{status: :pending}, %{status: :pending}] =
               Repo.all(Fund.TransactionModel) |> Enum.sort_by(& &1.id)
    end

    test "can create a fresh transaction after a previous one was marked :failed (UC-OPP-01.A1: retry)" do
      %{assignment: assignment, user: user} = setup_assignment()

      stub_provider_create_transaction()

      # First transaction → fail it (simulates the payment-failed webhook).
      {:ok, %{transaction: failed}} =
        Fund.Public.create_pay_in(assignment, user, %{
          "subject_count" => 10,
          "subject_reward" => 500,
          "aim_of_study" => "Ten-participant test with a valid aim-of-study text."
        })

      {:ok, _} = Fund.Public.fail_transaction(failed.transaction_id)

      # Retry — the researcher clicks "Confirm" again on a fresh PayInRequestForm.
      {:ok, %{transaction: retry}} =
        Fund.Public.create_pay_in(reload(assignment), user, %{
          "subject_count" => 10,
          "subject_reward" => 500,
          "aim_of_study" => "Ten-participant test with a valid aim-of-study text."
        })

      assert retry.id != failed.id
      assert retry.status == :pending
      assert retry.transaction_id != failed.transaction_id

      assert %{status: :failed} = Repo.get!(Fund.TransactionModel, failed.id)
      assert %{status: :pending} = Repo.get!(Fund.TransactionModel, retry.id)
    end

    test "a provider error leaves the assignment info saved, so a retry needs the reloaded assignment" do
      %{assignment: assignment, user: user} = setup_assignment()

      stub(ProviderMock, :get_merchant, fn _uid ->
        {:ok,
         %{
           uid: "m_create_pay_in",
           status: "active",
           kyc_level: 100,
           compliance_status: "verified"
         }}
      end)

      ProviderMock
      |> expect(:create_transaction, fn _request -> {:error, :provider_unavailable} end)

      attrs = %{
        "subject_count" => 10,
        "subject_reward" => 500,
        "aim_of_study" => "Ten-participant test with a valid aim-of-study text."
      }

      assert {:error, :provider_unavailable} =
               Fund.Public.create_pay_in(assignment, user, attrs)

      # The info was saved before the provider call, so the struct the form
      # still holds is stale and the update guard rejects it.
      assert {:error, %Ecto.Changeset{data: %Assignment.InfoModel{}}} =
               Fund.Public.create_pay_in(assignment, user, attrs)

      stub_provider_create_transaction()

      assert {:ok, %{transaction: %{status: :pending}}} =
               Fund.Public.create_pay_in(reload(assignment), user, attrs)
    end
  end

  # What `Assignment.PaidSlotsLogic.refresh_assignment/1` does before the
  # form is opened again.
  defp reload(%Assignment.Model{id: id}) do
    Assignment.Public.get!(id, Assignment.Model.preload_graph(:down))
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

    # `updated_at` has second precision. Backdating it makes the first
    # pay-in's save land in a later second, so reusing a stale assignment
    # always trips `Mica.Repo.multi_update_guard/3` instead of only sometimes.
    an_hour_ago =
      NaiveDateTime.utc_now() |> NaiveDateTime.add(-3600) |> NaiveDateTime.truncate(:second)

    info =
      Factories.insert!(:assignment_info, %{
        subject_count: 10,
        subject_reward: 500,
        inserted_at: an_hour_ago,
        updated_at: an_hour_ago
      })

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
    case Fund.CurrencyLedgerModel.get_by_currency(currency) do
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
