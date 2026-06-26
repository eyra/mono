defmodule Systems.Account.PayoutsViewBuilderTest do
  use Core.DataCase
  import Mox

  alias Systems.Account
  alias Systems.Assignment.CurrencyHelpers
  alias Systems.Fund
  alias Systems.Payment.ProviderMock
  alias Core.Factories

  setup :verify_on_exit!

  defp t(key), do: Gettext.dgettext(CoreWeb.Gettext, "eyra-account", key)

  describe "bank status" do
    test "no merchant -> not_verified (red, Add) without hitting OPP" do
      user = Factories.insert!(:member, %{creator: false})

      vm = Account.PayoutsViewBuilder.view_model(user, %{})

      assert vm.bank.status == :not_verified
      assert vm.bank.status_variant == :error
      assert vm.bank.button.action.event == "start_verification"
      assert vm.bank.button.face.label == t("payouts.bank.button.add")
    end

    test "bank approved -> verified (green, no button)" do
      user = Factories.insert!(:member, %{creator: false, merchant_uid: "m_v"})

      expect(ProviderMock, :list_bank_accounts, fn "m_v" ->
        {:ok, [%{uid: "ba", status: "approved", verification_url: nil}]}
      end)

      vm = Account.PayoutsViewBuilder.view_model(user, %{})

      assert vm.bank.status == :verified
      assert vm.bank.status_variant == :info
      assert vm.bank.button == nil
    end

    test "merchant verified + bank pending (with lingering url) -> pending (orange, no button)" do
      user = Factories.insert!(:member, %{creator: false, merchant_uid: "m_p"})

      # A pending account can still carry a verification_url; status must win.
      expect(ProviderMock, :list_bank_accounts, fn "m_p" ->
        {:ok, [%{uid: "ba", status: "pending", verification_url: "https://opp.test/ba/verify"}]}
      end)

      vm = Account.PayoutsViewBuilder.view_model(user, %{})

      assert vm.bank.status == :pending
      assert vm.bank.status_variant == :warning
      # Under review at OPP — no manual action; the badge updates reactively.
      assert vm.bank.button == nil
    end

    test "merchant verified + bank new (not yet verified) -> not_verified" do
      user = Factories.insert!(:member, %{creator: false, merchant_uid: "m_nv"})

      expect(ProviderMock, :list_bank_accounts, fn "m_nv" ->
        {:ok, [%{uid: "ba", status: "new", verification_url: "https://opp.test/ba/verify"}]}
      end)

      vm = Account.PayoutsViewBuilder.view_model(user, %{})

      assert vm.bank.status == :not_verified
    end

    test "bank approved -> verified even when merchant identity-KYC is still open" do
      user = Factories.insert!(:member, %{creator: false, merchant_uid: "m_b"})

      # No get_merchant expectation: the badge is derived from the bank account
      # only, so a lingering merchant overview_url (Level 400) is irrelevant.
      expect(ProviderMock, :list_bank_accounts, fn "m_b" ->
        {:ok, [%{uid: "ba", status: "approved", verification_url: nil}]}
      end)

      vm = Account.PayoutsViewBuilder.view_model(user, %{})

      assert vm.bank.status == :verified
      assert vm.bank.status_variant == :info
      assert vm.bank.status_label == t("payouts.bank.status.verified")
      assert vm.bank.button == nil
    end
  end

  describe "start_bank_verification (boots into iDEAL first)" do
    test "prefers the iDEAL bank flow even when the merchant still has an overview url" do
      user = Factories.insert!(:member, %{creator: false, merchant_uid: "m_b"})

      expect(ProviderMock, :get_merchant, fn "m_b" ->
        {:ok,
         %{
           uid: "m_b",
           status: "live",
           kyc_level: 0,
           compliance_status: "unverified",
           overview_url: "https://opp.test/overview/m_b"
         }}
      end)

      expect(ProviderMock, :list_bank_accounts, fn "m_b" ->
        {:ok, [%{uid: "ba", status: "new", verification_url: "https://opp.test/ba/verify"}]}
      end)

      assert {:bank, "https://opp.test/ba/verify"} = Fund.Public.start_bank_verification(user)
    end

    test "returns :verified once the bank account is approved (never the merchant overview)" do
      user = Factories.insert!(:member, %{creator: false, merchant_uid: "m_b"})

      expect(ProviderMock, :get_merchant, fn "m_b" ->
        {:ok,
         %{
           uid: "m_b",
           status: "live",
           kyc_level: 0,
           compliance_status: "unverified",
           overview_url: "https://opp.test/overview/m_b"
         }}
      end)

      expect(ProviderMock, :list_bank_accounts, fn "m_b" ->
        {:ok, [%{uid: "ba", status: "approved", verification_url: nil}]}
      end)

      assert :verified = Fund.Public.start_bank_verification(user)
    end
  end

  describe "bank_verification_modal/1" do
    test "builds a ConfirmationModal that hands off to OPP via http_get" do
      modal = Account.PayoutsViewBuilder.bank_verification_modal("https://opp.test/ba/verify")

      assert %LiveNest.Modal{style: :compact, element: element} = modal
      assert element.implementation == Frameworks.Pixel.ConfirmationModal

      assigns = Keyword.fetch!(element.options, :assigns)
      assert assigns.confirm_action == %{type: :http_get, to: "https://opp.test/ba/verify"}
      assert assigns.title == t("payouts.bank.modal.title")
      assert assigns.confirm_label == t("payouts.bank.modal.confirm")
    end
  end

  describe "phone_form_modal/1" do
    test "builds a PhoneForm modal for the given user" do
      user = Factories.insert!(:member, %{creator: false})

      modal = Account.PayoutsViewBuilder.phone_form_modal(user)

      assert %LiveNest.Modal{style: :compact, element: element} = modal
      assert element.implementation == Systems.Account.PhoneForm
      assert Keyword.fetch!(element.options, :user).id == user.id
    end
  end

  describe "overview" do
    test "no payouts -> empty overview" do
      user = Factories.insert!(:member, %{creator: false})

      vm = Account.PayoutsViewBuilder.view_model(user, %{})

      assert vm.overview.empty?
      assert vm.overview.years == []
    end

    test "groups payouts by year (newest first) with per-year totals and status labels" do
      user = Factories.insert!(:member, %{creator: false})
      payout(user, 500, :completed, ~N[2025-09-24 10:00:00])
      payout(user, 500, :completed, ~N[2025-09-25 10:00:00])
      payout(user, 1000, :pending, ~N[2024-03-01 10:00:00])

      vm = Account.PayoutsViewBuilder.view_model(user, %{})

      refute vm.overview.empty?
      assert vm.overview.years == [2025, 2024]
      assert length(vm.overview.rows_by_year[2025]) == 2
      assert length(vm.overview.rows_by_year[2024]) == 1

      assert vm.overview.totals_by_year[2025] == CurrencyHelpers.format_cents(1000)
      assert vm.overview.totals_by_year[2024] == CurrencyHelpers.format_cents(1000)

      [_date, amount, status] = hd(vm.overview.rows_by_year[2024])
      assert amount == CurrencyHelpers.format_cents(1000)
      assert status.text == t("payouts.status.pending")
      assert status.bg_color == "bg-warning"
    end

    test "only the given user's payouts are listed" do
      user = Factories.insert!(:member, %{creator: false})
      other = Factories.insert!(:member, %{creator: false})
      payout(user, 500, :completed, ~N[2025-01-01 10:00:00])
      payout(other, 9999, :completed, ~N[2025-01-01 10:00:00])

      vm = Account.PayoutsViewBuilder.view_model(user, %{})

      assert [[_date, amount, _status]] = vm.overview.rows_by_year[2025]
      assert amount == CurrencyHelpers.format_cents(500)
    end
  end

  defp payout(user, cents, status, inserted_at) do
    Repo.insert!(%Fund.PayoutModel{
      user_id: user.id,
      amount_cents: cents,
      currency: "eur",
      status: status,
      inserted_at: inserted_at,
      updated_at: inserted_at
    })
  end
end
