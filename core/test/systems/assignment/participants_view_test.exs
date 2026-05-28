defmodule Systems.Assignment.ParticipantsViewTest do
  @moduledoc """
  Regression coverage for the participants tab's "pending approvals" CTA
  banner. The full banner disappeared once in a silent refactor — these
  tests assert the rendering condition so the next refactor catches it
  at the test level instead of in production.
  """
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  alias Systems.Assignment.ParticipantsView

  describe "pending_approvals_banner/1" do
    test "renders the CTA when there are pending approvals" do
      html =
        render_component(&ParticipantsView.pending_approvals_banner/1, %{
          pending_approvals: [%{reward_id: 1}],
          target: :stub
        })

      assert html =~ ~s(data-testid="pending-approvals-cta")
    end

    test "renders nothing when there are no pending approvals" do
      html =
        render_component(&ParticipantsView.pending_approvals_banner/1, %{
          pending_approvals: [],
          target: :stub
        })

      refute html =~ ~s(data-testid="pending-approvals-cta")
    end

    test "wires the open_payout_modal event to the parent target" do
      html =
        render_component(&ParticipantsView.pending_approvals_banner/1, %{
          pending_approvals: [%{reward_id: 1}],
          target: :stub
        })

      assert html =~ ~s(phx-click="open_payout_modal")
    end

    test "renders the configured title and CTA copy" do
      html =
        render_component(&ParticipantsView.pending_approvals_banner/1, %{
          pending_approvals: [%{reward_id: 1}],
          target: :stub
        })

      assert html =~ "Participants waiting for pay out"
      assert html =~ "Check pay outs"
    end
  end
end
