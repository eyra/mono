defmodule Core.Accounts.NextActions.PromotePushStudent do
  @behaviour Systems.NextAction.ViewModel

  import CoreWeb.Gettext

  @impl Systems.NextAction.ViewModel
  def to_view_model(url_resolver, _count, _params) do
    %{
      title: dgettext("eyra-nextaction", "promote.push.student.title"),
      description: dgettext("eyra-nextaction", "promote.push.student.description"),
      cta: dgettext("eyra-nextaction", "promote.push.student.cta"),
      url: url_resolver.(CoreWeb.User.Settings, [])
    }
  end
end
