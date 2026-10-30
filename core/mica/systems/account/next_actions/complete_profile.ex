defmodule Systems.Account.NextActions.CompleteProfile do
  @behaviour Systems.NextAction.ViewModel
  use MicaWeb, :verified_routes

  use Gettext, backend: MicaWeb.Gettext

  @impl Systems.NextAction.ViewModel
  def to_view_model(_count, _params) do
    %{
      title: dgettext("eyra-nextaction", "complete.profile.title"),
      description: dgettext("eyra-nextaction", "complete.profile.description"),
      cta_label: dgettext("eyra-nextaction", "complete.profile.cta"),
      cta_action: %{type: :redirect, to: ~p"/user/account"}
    }
  end
end
