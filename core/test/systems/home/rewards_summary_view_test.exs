defmodule Systems.Home.RewardsSummaryViewTest do
  @moduledoc """
  Render-level coverage for the MS.6 handoff modal. The modal lives inline
  in the rewards summary card and is only rendered when the parent's
  `@show_handoff_modal?` assign is true.

  Event-handler coverage (eligibility -> show modal -> request_payout) is
  exercised at the Fund.Public level via payout_eligibility/1 and
  request_payout/1 tests in test/systems/fund/_public_test.exs.
  """
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  alias Systems.Home.RewardsSummaryView

  defp labels do
    %{
      payout_handoff_body: "🔒 You will leave Next to be sent to OPP.",
      payout_handoff_confirm: "Go to payout",
      payout_handoff_cancel: "Cancel"
    }
  end

  describe "handoff_modal/1" do
    test "renders the testid wrapper, body copy, and both buttons" do
      html =
        render_component(&RewardsSummaryView.handoff_modal/1, %{
          labels: labels(),
          target: :stub
        })

      assert html =~ ~s(data-testid="payout-handoff-modal")
      assert html =~ ~s(data-testid="payout-handoff-confirm")
      assert html =~ ~s(data-testid="payout-handoff-cancel")
      assert html =~ "🔒 You will leave Next to be sent to OPP."
      assert html =~ "Go to payout"
      assert html =~ "Cancel"
    end

    test "wires the confirm button to the confirm_handoff event on the target" do
      html =
        render_component(&RewardsSummaryView.handoff_modal/1, %{
          labels: labels(),
          target: :stub
        })

      assert html =~ ~s(phx-click="confirm_handoff")
    end

    test "wires the cancel button to the cancel_handoff event on the target" do
      html =
        render_component(&RewardsSummaryView.handoff_modal/1, %{
          labels: labels(),
          target: :stub
        })

      assert html =~ ~s(phx-click="cancel_handoff")
    end
  end
end
