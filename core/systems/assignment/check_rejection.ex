defmodule Systems.Assignment.CheckRejection do
  @behaviour Systems.NextAction.ViewModel
  use CoreWeb, :verified_routes

  use Gettext, backend: CoreWeb.Gettext

  @impl Systems.NextAction.ViewModel
  def to_view_model(_count, %{"id" => id}) do
    %{
      title: dgettext("eyra-nextaction", "assignment.check.rejection.title"),
      description: dgettext("eyra-nextaction", "assignment.check.rejection.description"),
      cta_label: dgettext("eyra-nextaction", "assignment.check.rejection.cta"),
      cta_action: %{type: :redirect, to: ~p"/assignment/#{id}/landing"}
    }
  end
end
