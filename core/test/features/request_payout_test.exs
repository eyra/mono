defmodule CoreWeb.Features.RequestPayoutTest do
  @moduledoc """
  Wallaby version of the Playwright `request_payout.spec.ts` (UC-OPP-06).

  Asserts the participant payout-request → KYC handoff flow: a participant
  with an approved reward clicks "Uitbetalen" (`payout-button`); their
  merchant account isn't KYC-verified at the provider, so
  `Fund.Public.prepare_payout/1` returns `{:error, {:kyc_required, url}}`
  and the ConfirmationModal is composed with the KYC labels + an
  external-URL confirm action (UC-OPP-06.A1).

  The precondition state (participant with approved reward) is built via
  Factories; `ProviderMock` is stubbed to put the merchant in a
  not-yet-verified state so the KYC branch fires. The test does not
  follow the external OPP onboarding URL (the modal's confirm button
  redirects to a real KYC flow in production); it just verifies the
  modal is shown.
  """

  use CoreWeb.FeatureCase

  import Mox

  alias Systems.Fund
  alias Systems.Payment.ProviderMock

  setup :set_mox_global
  setup :verify_on_exit!

  setup do
    Factories.insert!(:currency_ledger, %{currency: :EUR})
    :ok
  end

  @tag :feature
  feature "participant sees KYC handoff modal after requesting payout",
          %{session: session} do
    merchant_uid = "m_kyc_test"

    # Merchant exists at the provider but isn't verified — drives the
    # `{:error, {:kyc_required, overview_url}}` branch of
    # Fund.Public.prepare_payout/1.
    ProviderMock
    |> stub(:get_merchant, fn ^merchant_uid ->
      {:ok,
       %{
         uid: merchant_uid,
         status: "pending",
         kyc_level: 0,
         compliance_status: "unverified",
         overview_url: "https://opp.test/kyc-onboarding"
       }}
    end)
    |> stub(:list_bank_accounts, fn ^merchant_uid ->
      {:ok, [%{uid: "ba_test", status: "approved", verification_url: nil}]}
    end)

    password = Factories.valid_user_password()

    participant =
      Factories.insert!(:member, %{
        password: password,
        confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        verified_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        creator: false,
        merchant_uid: merchant_uid
      })

    currency = Factories.insert!(:currency, %{name: "eur_test"})
    fund = Fund.Factories.create_fund("payout_fund_#{participant.id}", currency)

    # Approved reward — what makes `payout-button` visible on the home page.
    # Amount = 1000 (€10), well above the €5 payout threshold (SF-OPP-06).
    Factories.insert!(:reward, %{
      user: participant,
      fund: fund,
      amount: 1000,
      status: :approved,
      idempotence_key: "rp-#{System.unique_integer([:positive])}"
    })

    session
    |> visit("/user/signin")
    |> fill_in(Query.css("[data-testid='signin-email-input']"),
      with: participant.email
    )
    |> fill_in(Query.css("[data-testid='signin-password-input']"), with: password)
    |> click(Query.css("[data-testid='signin-submit-button']"))
    |> visit("/")
    |> assert_has(Query.css("[data-testid='payout-button']"))
    |> click(Query.css("[data-testid='payout-button']"))
    |> assert_has(Query.css("[data-testid='confirmation-modal-confirm-button']"))
    |> assert_has(Query.css("[data-testid='confirmation-modal-cancel-button']"))
  end
end
