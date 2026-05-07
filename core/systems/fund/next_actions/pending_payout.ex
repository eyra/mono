defmodule Systems.Fund.NextActions.PendingPayout do
  @moduledoc """
  Next-action surfaced to the researcher when one or more participant rewards
  on an assignment are awaiting approval (status `:pending_approval`).

  Created when a participant completes their assignment task; cleared once no
  pending approvals remain on the assignment. The CTA links to the assignment's
  pay-out page where the researcher can approve, decline, or override past
  decisions.
  """
  @behaviour Systems.NextAction.ViewModel
  use CoreWeb, :verified_routes

  use Gettext, backend: CoreWeb.Gettext

  @impl Systems.NextAction.ViewModel
  def to_view_model(_count, %{"assignment_id" => assignment_id}) do
    %{
      title: dgettext("eyra-nextaction", "fund.pending_payout.title"),
      description: dgettext("eyra-nextaction", "fund.pending_payout.description"),
      cta_label: dgettext("eyra-nextaction", "fund.pending_payout.cta"),
      cta_action: %{type: :redirect, to: ~p"/assignment/#{assignment_id}/payout"}
    }
  end
end
