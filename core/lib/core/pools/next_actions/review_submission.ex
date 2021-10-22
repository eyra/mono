defmodule Core.Pools.ReviewSubmission do
  @behaviour Systems.NextAction.ViewModel

  import CoreWeb.Gettext

  @impl Systems.NextAction.ViewModel
  def to_view_model(url_resolver, _count, _params) do
    %{
      title: dgettext("eyra-nextaction", "review.submission.title"),
      description: dgettext("eyra-nextaction", "review.submission.description"),
      cta: dgettext("eyra-nextaction", "review.submission.cta"),
      url: url_resolver.(Link.Pool.OverviewPage, tab: "campaigns")
    }
  end
end
