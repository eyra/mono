defmodule CoreWeb.Features.FundAssignmentTest do
  @moduledoc """
  Wallaby version of the Playwright `fund_assignment.spec.ts` (UC-OPP-01).

  Researcher signs in → creates project + questionnaire item → navigates to
  the Participants tab → opens BudgetForm → fills aim / reward / slots →
  confirms → clicks through the local payment simulator → sees the
  `:completed` transaction card.

  Lives in Wallaby (not Playwright) because the payment provider is mocked
  via Mox. Playwright E2E targets real deployments; on the OPP-sandbox
  staging it cannot run this flow without a brittle session-mutating
  override. Wallaby runs in-process against the Mox `ProviderMock` so it's
  deterministic and works on every dev/CI run.
  """

  use CoreWeb.FeatureCase

  import Mox

  alias Systems.Payment.ProviderMock

  setup :set_mox_global
  setup :verify_on_exit!

  setup do
    Factories.insert!(:currency_ledger, %{currency: :EUR})
    :ok
  end

  @card_selector "[data-testid^='card_']"

  @tag :feature
  feature "researcher can assign budget to a questionnaire and complete local payment",
          %{session: session} do
    # Provider mock: payment_url points to the in-app local simulator
    # (`/payment/local/<uid>`), available in test env via
    # `enable_e2e_support: true`. The simulator's `Complete` button
    # synchronously calls `Budget.Public.complete_transaction/1` and
    # redirects back to the assignment.
    ProviderMock
    |> stub(:get_merchant, fn _uid ->
      {:ok, %{uid: "merchant-1", status: "active", kyc_level: 100, kyc_status: "verified"}}
    end)
    |> stub(:create_transaction, fn _request ->
      uid = Ecto.UUID.generate()

      {:ok,
       %{
         uid: uid,
         payment_url: "/payment/local/#{uid}",
         status: "created",
         amount: 5000
       }}
    end)

    password = Factories.valid_user_password()

    researcher =
      Factories.insert!(:member, %{
        password: password,
        confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        verified_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        creator: true,
        # Pre-populated so create_pay_in skips ensure_merchant_for and
        # uses the mocked `get_merchant/1` path.
        merchant_uid: "merchant-1"
      })

    session
    |> visit("/user/signin?tab=creator")
    |> fill_in(Query.css("[data-testid='signin-email-input']"), with: researcher.email)
    |> fill_in(Query.css("[data-testid='signin-password-input']"), with: password)
    |> click(Query.css("[data-testid='signin-submit-button']"))
    |> assert_has(Query.css("[data-testid='create-first-project-button']"))
    |> click(Query.css("[data-testid='create-first-project-button']"))
    |> assert_has(Query.css(@card_selector, count: 1))
    |> click(Query.css(@card_selector))
    |> assert_has(Query.css("[data-testid='create-first-item-button']"))
    |> click(Query.css("[data-testid='create-first-item-button']"))
    |> assert_has(Query.css("[data-testid='selector-item-questionnaire']"))
    |> click(Query.css("[data-testid='selector-item-questionnaire']"))
    |> click(Query.css("[data-testid='create-item-button']"))
    |> assert_has(Query.css(@card_selector, count: 1))
    |> click(Query.css(@card_selector))
    |> assert_has(Query.css("[data-testid='assignment-tab-participants']"))
    |> click(Query.css("[data-testid='assignment-tab-participants']"))
    |> assert_has(Query.css("[data-testid='pay-add-participants-button']"))
    |> click(Query.css("[data-testid='pay-add-participants-button']"))
    |> fill_in(Query.css("[data-testid='budget-form-aim-input']"),
      with: "Wallaby fund test"
    )
    |> fill_in(Query.css("[data-testid='budget-form-reward-input']"), with: "5.00")
    |> fill_in(Query.css("[data-testid='budget-form-slots-input']"), with: "10")
    # The slots field has phx-debounce="300"; the confirm button stays
    # disabled (cursor-not-allowed) until the LV processes update_slots.
    # Wait on the button-state transition before clicking — same pattern
    # the Playwright spec used. Without this we'd race the debounce and
    # confirm would no-op on subject_count=0.
    |> assert_has(
      Query.css("[data-testid='budget-form-confirm-button']:not(.cursor-not-allowed)")
    )
    |> click(Query.css("[data-testid='budget-form-confirm-button']"))
    |> assert_has(Query.css("[data-testid='local-payment-complete-button']"))
    |> click(Query.css("[data-testid='local-payment-complete-button']"))
    |> assert_has(Query.css("[data-testid='transaction-card-completed']"))
  end
end
