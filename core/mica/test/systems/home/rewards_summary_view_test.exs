defmodule Systems.Home.RewardsSummaryViewTest do
  @moduledoc """
  Unit coverage for the payout handoff modal *configuration*: compose/2 maps the
  payout handoff to the shared ConfirmationModal assigns. The handler dispatch —
  including the redirect to the account page when the bank account still needs
  verification — is covered by the handlers test; rendered modal chrome by the
  ConfirmationModal component test.
  """
  use ExUnit.Case, async: true

  alias Frameworks.Pixel
  alias Systems.Home.RewardsSummaryView

  @labels %{
    payout_handoff_title: "Start payout",
    payout_handoff_body: "PAYOUT body",
    payout_handoff_confirm: "Go to payout",
    payout_handoff_cancel: "Cancel",
    payout_verify_title: "Bank account not verified",
    payout_verify_body: "Verify your bank account first",
    payout_verify_confirm: "Go to verification"
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

    test "verify mode maps to the verify labels + a link to the account payouts tab" do
      assert %{
               module: Pixel.ConfirmationModal,
               params: %{
                 assigns: %{
                   title: "Bank account not verified",
                   body: "Verify your bank account first",
                   confirm_label: "Go to verification",
                   cancel_label: "Cancel",
                   confirm_action: %{type: :http_get, to: "/user/account?tab=payouts"}
                 }
               }
             } =
               RewardsSummaryView.compose(:handoff_modal, %{
                 handoff_mode: :verify,
                 labels: @labels
               })
    end
  end
end
