defmodule Systems.Pool.ReviewSubmission do
  @behaviour Systems.NextAction.ViewModel
  use CoreWeb, :verified_routes

  import CoreWeb.Gettext

  @impl Systems.NextAction.ViewModel
  def to_view_model(_count, %{"id" => id}) do
    %{
      title: dgettext("eyra-nextaction", "review.submission.title"),
      description: dgettext("eyra-nextaction", "review.submission.description"),
      cta_label: dgettext("eyra-nextaction", "review.submission.cta"),
      cta_action: %{
        type: :redirect,
        to: ~p"/pool/#{id}/detail?tab=adverts"
      }
    }
  end
end
