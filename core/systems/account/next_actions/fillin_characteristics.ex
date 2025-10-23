defmodule Systems.Account.NextActions.FillinCharacteristics do
  @behaviour Systems.NextAction.ViewModel
  use CoreWeb, :verified_routes

  use Gettext, backend: CoreWeb.Gettext

  @impl Systems.NextAction.ViewModel
  def to_view_model(_count, _params) do
    %{
      title: dgettext("eyra-nextaction", "fillin.characteristics.title"),
      description: dgettext("eyra-nextaction", "fillin.characteristics.description"),
      cta_label: dgettext("eyra-nextaction", "fillin.characteristics.cta"),
      cta_action: %{type: :redirect, to: ~p"/user/profile?tab=features"}
    }
  end
end
