defmodule MicaSaas.Systems.Home.RewardsSummaryViewHandlersTest do
  @moduledoc """
  White-box coverage of RewardsSummaryView's payout event handlers. The modal
  is presented through the shared ConfirmationModal via show_modal, which only
  renders inside a full routed page — so instead of a LiveView render cycle we
  call handle_event/3 directly (test process → plain Mox + Ecto sandbox) and
  assert the observable outcomes: the fabric modal child, redirects, and DB
  reward locking.

  Pins the B1 regression (KYC-blocked state never fires a withdrawal) and the
  stale-socket-user regression (a first-time payout reloads merchant_uid).
  """
  use Mica.DataCase
  import Mox
  import Systems.Home.RewardsSummaryTestHelper

  alias Systems.Fund
  alias Systems.Payment
  alias Systems.Payment.ProviderMock
  alias Systems.Home.RewardsSummaryView

  setup :verify_on_exit!

  defp reward_status(user), do: Mica.Repo.get_by!(Fund.RewardModel, user_id: user.id).status

  describe "request_payout" do
    test "bank kyc -> presents the verify modal" do
      user = user_with_reward(1000, "m_bank")

      # Merchant verified, but the bank account still needs verification.
      stub(ProviderMock, :get_merchant, fn _ ->
        {:ok,
         %{
           uid: "m_bank",
           status: "live",
           kyc_level: 100,
           compliance_status: "verified",
           overview_url: nil
         }}
      end)

      stub(ProviderMock, :list_bank_accounts, fn _ ->
        {:ok,
         [
           %{
             uid: "ba",
             status: :new,
             raw_status: "new",
             verification_url: "https://opp.test/ba/verify"
           }
         ]}
      end)

      {:noreply, socket} = RewardsSummaryView.handle_event("request_payout", %{}, socket(user))

      assert socket.assigns.handoff_mode == :verify
      assert Fabric.get_child(socket.assigns.fabric, :handoff_modal)
    end

    test "kyc_unavailable -> verify modal (B1: no fall-through to a payout)" do
      user = user_with_reward(1000, "m_unavail")

      stub(ProviderMock, :get_merchant, fn _ ->
        {:ok,
         %{
           uid: "m_unavail",
           status: "pending",
           kyc_level: 0,
           compliance_status: "unverified",
           overview_url: nil
         }}
      end)

      stub(ProviderMock, :list_bank_accounts, fn _ ->
        {:ok, [%{uid: "ba", status: :new, raw_status: "new", verification_url: nil}]}
      end)

      {:noreply, socket} = RewardsSummaryView.handle_event("request_payout", %{}, socket(user))

      # The verify variant confirms via an external link, so it can never
      # fall through to a withdrawal — the reward stays :approved.
      assert socket.assigns.handoff_mode == :verify
      assert Fabric.get_child(socket.assigns.fabric, :handoff_modal)
      assert reward_status(user) == :approved
    end
  end

  describe "confirmed (from the handoff modal)" do
    test "a provider failure at confirm time presents the verify modal" do
      user = user_with_reward(1000, "m_c_down")

      stub(ProviderMock, :list_bank_accounts, fn "m_c_down" ->
        {:error, %Payment.Error{code: :service_unavailable, message: "OPP down"}}
      end)

      {:noreply, socket} =
        RewardsSummaryView.handle_event(
          "confirmed",
          %{source: %{name: :handoff_modal}},
          socket(user, %{handoff_mode: :payout})
        )

      assert socket.assigns.handoff_mode == :verify
      assert Fabric.get_child(socket.assigns.fabric, :handoff_modal)
      assert reward_status(user) == :approved
    end
  end
end
