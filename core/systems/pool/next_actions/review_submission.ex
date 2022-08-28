defmodule Systems.Pool.ReviewSubmission do
  @behaviour Systems.NextAction.ViewModel

  import CoreWeb.Gettext

  @impl Systems.NextAction.ViewModel
  def to_view_model(url_resolver, _count, %{"id" => id}) do
    %{
      title: dgettext("eyra-nextaction", "review.submission.title"),
      description: dgettext("eyra-nextaction", "review.submission.description"),
      cta_label: dgettext("eyra-nextaction", "review.submission.cta"),
      cta_action: %{
        type: :redirect,
        to: url_resolver.(Systems.Pool.DetailPage, id: id, tab: "campaigns")
      }
    }
  end
end
