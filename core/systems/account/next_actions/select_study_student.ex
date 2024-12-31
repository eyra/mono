defmodule Systems.Account.NextActions.SelectStudyStudent do
  @behaviour Systems.NextAction.ViewModel
  use CoreWeb, :verified_routes

  use Gettext, backend: CoreWeb.Gettext

  @impl Systems.NextAction.ViewModel
  def to_view_model(_count, _params) do
    %{
      title: dgettext("eyra-nextaction", "select.study.student.title"),
      description: dgettext("eyra-nextaction", "select.study.student.description"),
      cta_label: dgettext("eyra-nextaction", "select.study.student.cta"),
      cta_action: %{type: :redirect, to: ~p"/user/profile?tab=study"}
    }
  end
end
