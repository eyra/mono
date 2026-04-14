defmodule Systems.Assignment.CheckPayouts do
  @behaviour Systems.NextAction.ViewModel
  use CoreWeb, :verified_routes

  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Assignment

  @impl Systems.NextAction.ViewModel
  def to_view_model(_count, %{"id" => id}) do
    pending = Assignment.Public.count_pending_payouts(%Assignment.Model{id: id})

    %{
      title: dgettext("eyra-nextaction", "assignment.check.payouts.title"),
      description: dgettext("eyra-nextaction", "assignment.check.payouts.description"),
      cta_label: dgettext("eyra-nextaction", "assignment.check.payouts.cta", count: pending),
      cta_action: %{type: :redirect, to: ~p"/assignment/#{id}/content"}
    }
  end
end
