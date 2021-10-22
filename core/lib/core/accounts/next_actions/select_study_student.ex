defmodule Core.Accounts.NextActions.SelectStudyStudent do
  @behaviour Systems.NextAction.ViewModel

  import CoreWeb.Gettext

  @impl Systems.NextAction.ViewModel
  def to_view_model(url_resolver, _count, _params) do
    %{
      title: dgettext("eyra-nextaction", "select.study.student.title"),
      description: dgettext("eyra-nextaction", "select.study.student.description"),
      cta: dgettext("eyra-nextaction", "select.study.student.cta"),
      url: url_resolver.(CoreWeb.User.Profile, tab: "study")
    }
  end
end
