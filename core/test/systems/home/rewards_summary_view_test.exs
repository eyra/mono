defmodule Systems.Home.RewardsSummaryViewTest do
  @moduledoc """
  Unit coverage for the payout handoff modal *configuration*: compose/2 maps
  the handoff mode to the right shared ConfirmationModal assigns (title, body,
  confirm/cancel labels). The handler dispatch + the rendered modal chrome are
  covered by Fund.Public tests and the ConfirmationModal component test.
  """
  use ExUnit.Case, async: true

  alias Frameworks.Pixel
  alias Systems.Home.RewardsSummaryView

  @labels %{
    payout_handoff_title: "Start payout",
    payout_handoff_body: "PAYOUT body",
    payout_handoff_confirm: "Go to payout",
    payout_handoff_cancel: "Cancel",
    payout_kyc_title: "Verification required",
    payout_kyc_body: "KYC body",
    payout_kyc_confirm: "Continue to verification"
  }

  describe "compose/2 :handoff_modal" do
    test "payout mode maps to the payout labels on ConfirmationModal" do
      assert %{
               module: Pixel.ConfirmationModal,
               params: %{
                 assigns: %{
                   title: "Start payout",
                   body: "PAYOUT body",
                   confirm_label: "Go to payout",
                   cancel_label: "Cancel"
                 }
               }
             } =
               RewardsSummaryView.compose(:handoff_modal, %{
                 handoff_mode: :payout,
                 labels: @labels
               })
    end

    test "kyc mode maps to the kyc labels + an external-link confirm action" do
      assert %{
               module: Pixel.ConfirmationModal,
               params: %{
                 assigns: %{
                   title: "Verification required",
                   body: "KYC body",
                   confirm_label: "Continue to verification",
                   cancel_label: "Cancel",
                   confirm_action: %{type: :http_get, to: "https://opp.test/kyc"}
                 }
               }
             } =
               RewardsSummaryView.compose(:handoff_modal, %{
                 handoff_mode: :kyc,
                 kyc_overview_url: "https://opp.test/kyc",
                 labels: @labels
               })
    end
  end
end
