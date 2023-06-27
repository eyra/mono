defmodule Core.Accounts.NextActions.CompleteProfile do
  @behaviour Systems.NextAction.ViewModel
  use CoreWeb, :verified_routes

  import CoreWeb.Gettext

  @impl Systems.NextAction.ViewModel
  def to_view_model(_count, _params) do
    %{
      title: dgettext("eyra-nextaction", "complete.profile.title"),
      description: dgettext("eyra-nextaction", "complete.profile.description"),
      cta_label: dgettext("eyra-nextaction", "complete.profile.cta"),
      cta_action: %{type: :redirect, to: ~p"/user/profile"}
    }
  end
end
