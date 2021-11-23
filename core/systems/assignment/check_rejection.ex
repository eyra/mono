defmodule Systems.Assignment.CheckRejection do
  @behaviour Systems.NextAction.ViewModel

  import CoreWeb.Gettext

  @impl Systems.NextAction.ViewModel
  def to_view_model(url_resolver, _count, %{"id" => id}) do
    %{
      title: dgettext("eyra-nextaction", "assignment.check.rejection.title"),
      description: dgettext("eyra-nextaction", "assignment.check.rejection.description"),
      cta_label: dgettext("eyra-nextaction", "assignment.check.rejection.cta"),
      cta_action: %{
        type: :redirect,
        to: url_resolver.(Systems.Assignment.LandingPage, id)
      }
    }
  end
end
