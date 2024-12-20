defmodule Systems.Account.NextActions.PromotePushStudent do
  @behaviour Systems.NextAction.ViewModel
  use CoreWeb, :verified_routes

  use Gettext, backend: CoreWeb.Gettext

  @impl Systems.NextAction.ViewModel
  def to_view_model(_count, _params) do
    %{
      title: dgettext("eyra-nextaction", "promote.push.student.title"),
      description: dgettext("eyra-nextaction", "promote.push.student.description"),
      cta_label: dgettext("eyra-nextaction", "promote.push.student.cta"),
      cta_action: %{type: :redirect, to: ~p"/user/profile?tab=settings"}
    }
  end
end
