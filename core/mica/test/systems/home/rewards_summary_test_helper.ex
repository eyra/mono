defmodule Systems.Home.RewardsSummaryTestHelper do
  @moduledoc "The socket and the rewarded user the RewardsSummaryView handler tests start from."

  alias Mica.Factories
  alias Systems.Fund

  @labels %{
    title: "Rewards",
    pending_pill: "P",
    pending_caption: "",
    approved_pill: "A",
    approved_caption: "min €5",
    rejected_pill: "R",
    payout_button: "Uitbetalen",
    payout_below_threshold: "Minimum €5 required",
    payout_handoff_title: "Start payout",
    payout_handoff_body: "PAYOUT body",
    payout_handoff_confirm: "Go to payout",
    payout_handoff_cancel: "Cancel",
    payout_verify_title: "Bank account not verified",
    payout_verify_body: "Verify your bank account first",
    payout_verify_confirm: "Go to verification",
    payout_awaiting_title: "Verification in progress",
    payout_awaiting_body: "Your bank is being reviewed by the payment provider",
    payout_awaiting_confirm: "OK",
    donate_button: "Donate",
    donate_handoff_title: "Donate to Eyra",
    donate_handoff_body: "DONATE body",
    donate_handoff_confirm: "Yes, donate",
    donate_thanks: "Thank you for your donation!",
    donate_failed: "Donation failed",
    donate_pending: "Still confirming your donation",
    donate_in_progress: "Your donation is being processed",
    donated_total: "Donated to Eyra"
  }

  def socket(user, extra \\ %{}) do
    assigns =
      Map.merge(
        %{
          __changed__: %{},
          fabric: Fabric.Factories.create_fabric(),
          myself: %Phoenix.LiveComponent.CID{cid: 1},
          user: user,
          labels: @labels,
          handoff_mode: :payout,
          payout_currency: "euro",
          pending_cents: 0,
          approved_cents: 1000,
          rejected_cents: 0,
          donating_cents: 0,
          donated_cents: 0,
          donate_enabled?: true
        },
        extra
      )

    %Phoenix.LiveView.Socket{assigns: assigns}
  end

  def user_with_reward(amount, merchant_uid) do
    currency = Fund.Factories.create_currency("euro", :legal, "€", 2)

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
end
