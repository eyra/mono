defmodule Systems.Assignment.NextActions.ContributionReviewed do
  @moduledoc """
  Next-action surfaced to a participant after the owner has reviewed their
  contribution — variants for `accepted` and `declined`. Links back to the
  assignment's participation outcome page.
  """
  @behaviour Systems.NextAction.ViewModel

  use CoreWeb, :verified_routes
  use Gettext, backend: CoreWeb.Gettext

  @impl Systems.NextAction.ViewModel
  def to_view_model(_count, %{"assignment_id" => assignment_id, "outcome" => outcome}) do
    %{
      title: title(outcome),
      description: description(outcome),
      cta_label: dgettext("eyra-nextaction", "assignment.contribution_reviewed.cta"),
      cta_action: %{
        type: :redirect,
        to: ~p"/assignment/#{assignment_id}"
      }
    }
  end

  defp title("accepted"), do: dgettext("eyra-nextaction", "assignment.contribution_reviewed.accepted.title")

  defp title("declined"), do: dgettext("eyra-nextaction", "assignment.contribution_reviewed.declined.title")

  defp description("accepted"), do: dgettext("eyra-nextaction", "assignment.contribution_reviewed.accepted.description")

  defp description("declined"), do: dgettext("eyra-nextaction", "assignment.contribution_reviewed.declined.description")
end
