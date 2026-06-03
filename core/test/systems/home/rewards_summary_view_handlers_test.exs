defmodule Systems.Home.RewardsSummaryViewHandlersTest do
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
  use Core.DataCase
  import Mox

  alias Core.Factories
  alias Systems.Fund
  alias Systems.Payment.ProviderMock
  alias Systems.Home.RewardsSummaryView

  setup :verify_on_exit!

  @labels %{
    title: "Rewards",
    pending_pill: "P",
    pending_caption: "",
    approved_pill: "A",
    approved_caption: "min €5",
    rejected_pill: "R",
    payout_button: "Uitbetalen",
    payout_success: "Payout started",
    payout_below_threshold: "Minimum €5 required",
    payout_failed: "Could not start payout",
    payout_handoff_title: "Start payout",
    payout_handoff_body: "PAYOUT body",
    payout_handoff_confirm: "Go to payout",
    payout_handoff_cancel: "Cancel",
    payout_kyc_title: "Verification required",
    payout_kyc_body: "KYC body",
    payout_kyc_confirm: "Continue to OPP"
  }

  defp socket(user, extra \\ %{}) do
    assigns =
      Map.merge(
        %{
          __changed__: %{},
          fabric: Fabric.Factories.create_fabric(),
          myself: %Phoenix.LiveComponent.CID{cid: 1},
          user: user,
          labels: @labels,
          handoff_mode: :payout,
          kyc_overview_url: nil,
          pending_cents: 0,
          approved_cents: 1000,
          rejected_cents: 0
        },
        extra
      )

    %Phoenix.LiveView.Socket{assigns: assigns}
  end

  defp user_with_reward(amount, merchant_uid) do
    currency =
      Fund.Factories.create_currency(
        "h_cur_#{System.unique_integer([:positive])}",
        :legal,
        "ƒ",
        2
      )

    fund = Fund.Factories.create_fund("h_fund_#{System.unique_integer([:positive])}", currency)
    user = Factories.insert!(:member, %{creator: false, merchant_uid: merchant_uid})

    Factories.insert!(:reward, %{
      user: user,
      fund: fund,
      amount: amount,
      status: :approved,
      idempotence_key: "h-#{System.unique_integer([:positive])}"
    })

    user
  end

  defp reward_status(user), do: Core.Repo.get_by!(Fund.RewardModel, user_id: user.id).status

  defp stub_ready(merchant_uid) do
    stub(ProviderMock, :get_merchant, fn ^merchant_uid ->
      {:ok,
       %{
         uid: merchant_uid,
         status: "live",
         kyc_level: 100,
         compliance_status: "verified",
         overview_url: nil
       }}
    end)

    stub(ProviderMock, :list_bank_accounts, fn ^merchant_uid ->
      {:ok, [%{uid: "ba_ok", status: "approved", verification_url: nil}]}
    end)
  end

  describe "request_payout" do
    test "ready -> composes the payout handoff modal" do
      user = user_with_reward(1000, "m_rp")
      stub_ready("m_rp")

      {:noreply, socket} = RewardsSummaryView.handle_event("request_payout", %{}, socket(user))

      assert socket.assigns.handoff_mode == :payout
      assert Fabric.get_child(socket.assigns.fabric, :handoff_modal)
    end

    test "kyc -> composes the kyc handoff modal with the overview url" do
      user = user_with_reward(1000, "m_kyc")

      stub(ProviderMock, :get_merchant, fn _ ->
        {:ok,
         %{
           uid: "m_kyc",
           status: "pending",
           kyc_level: 0,
           compliance_status: "unverified",
           overview_url: "https://opp.test/kyc"
         }}
      end)

      stub(ProviderMock, :list_bank_accounts, fn _ ->
        {:ok, [%{uid: "ba", status: "approved", verification_url: nil}]}
      end)

      {:noreply, socket} = RewardsSummaryView.handle_event("request_payout", %{}, socket(user))

      assert socket.assigns.handoff_mode == :kyc
      assert socket.assigns.kyc_overview_url == "https://opp.test/kyc"
      assert Fabric.get_child(socket.assigns.fabric, :handoff_modal)
    end

    test "kyc_unavailable -> no modal (B1: no fall-through to a payout)" do
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
        {:ok, [%{uid: "ba", status: "new", verification_url: nil}]}
      end)

      {:noreply, socket} = RewardsSummaryView.handle_event("request_payout", %{}, socket(user))

      refute Fabric.get_child(socket.assigns.fabric, :handoff_modal)
      assert reward_status(user) == :approved
    end

    test "below_threshold -> no modal, no OPP call" do
      user = user_with_reward(100, "m_low")
      # No ProviderMock stub -> Mox raises if any OPP call is made.

      {:noreply, socket} = RewardsSummaryView.handle_event("request_payout", %{}, socket(user))

      refute Fabric.get_child(socket.assigns.fabric, :handoff_modal)
    end
  end

  describe "confirmed (from the handoff modal)" do
    # Note: the KYC variant confirms via an external <a href> link (see the
    # compose/2 + ConfirmationModal tests), so it never sends a server
    # "confirmed" event — there is deliberately no server-side KYC confirm
    # path here. Only the payout variant reaches the server.

    test "payout variant fires the withdrawal and locks the rewards" do
      user = user_with_reward(1000, "m_c_pay")
      stub_ready("m_c_pay")

      stub(ProviderMock, :create_withdrawal, fn "m_c_pay", :eur, %{amount: 1000} ->
        {:ok, %{uid: "w", status: "created", amount: 1000}}
      end)

      {:noreply, _socket} =
        RewardsSummaryView.handle_event(
          "confirmed",
          %{source: %{name: :handoff_modal}},
          socket(user, %{handoff_mode: :payout})
        )

      assert reward_status(user) == :pending_payout
    end

    test "stale-user regression: confirm reloads merchant_uid provisioned this session" do
      # DB user has a merchant_uid, but the socket carries a stale struct with
      # merchant_uid: nil (as it would right after prepare_payout provisioned it).
      user = user_with_reward(1000, "m_provisioned")
      stub_ready("m_provisioned")

      stub(ProviderMock, :create_withdrawal, fn "m_provisioned", :eur, _ ->
        {:ok, %{uid: "w", status: "created", amount: 1000}}
      end)

      stale = %{user | merchant_uid: nil}

      {:noreply, _socket} =
        RewardsSummaryView.handle_event(
          "confirmed",
          %{source: %{name: :handoff_modal}},
          socket(stale, %{handoff_mode: :payout})
        )

      assert reward_status(user) == :pending_payout
    end
  end

  describe "cancelled (from the handoff modal)" do
    test "removes the modal child without firing a payout" do
      user = user_with_reward(1000, "m_cancel")
      stub_ready("m_cancel")

      # Open the modal first.
      {:noreply, opened} = RewardsSummaryView.handle_event("request_payout", %{}, socket(user))
      assert Fabric.get_child(opened.assigns.fabric, :handoff_modal)

      {:noreply, closed} =
        RewardsSummaryView.handle_event("cancelled", %{source: %{name: :handoff_modal}}, opened)

      refute Fabric.get_child(closed.assigns.fabric, :handoff_modal)
      assert reward_status(user) == :approved
    end
  end
end
