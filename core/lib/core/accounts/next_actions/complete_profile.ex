defmodule Core.Accounts.NextActions.CompleteProfile do
  @behaviour Core.NextActions.ViewModel

  import CoreWeb.Gettext

  @impl Core.NextActions.ViewModel
  def to_view_model(url_resolver, _count, _params) do
    %{
      title: dgettext("eyra-nextaction", "complete.profile.title"),
      description: dgettext("eyra-nextaction", "complete.profile.description"),
      cta: dgettext("eyra-nextaction", "complete.profile.cta"),
      url: url_resolver.(CoreWeb.User.Profile, [])
    }
  end
end
