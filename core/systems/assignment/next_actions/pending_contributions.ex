defmodule Systems.Assignment.NextActions.PendingContributions do
  @moduledoc """
  Next-action surfaced to the researcher when one or more participant rewards
  on an assignment are awaiting approval (status `:pending_approval`).

  Created when a participant completes their assignment task; cleared once no
  pending approvals remain on the assignment. The CTA links to the assignment's
  Contributions tab where the researcher can approve or decline each
  contribution.
  """
  @behaviour Systems.NextAction.ViewModel
  use CoreWeb, :verified_routes

  use Gettext, backend: CoreWeb.Gettext

  alias Core.Repo
  alias Systems.Assignment

  @max_description_length 80

  @impl Systems.NextAction.ViewModel
  def to_view_model(_count, %{"assignment_id" => assignment_id}) do
    name = resolve_assignment_name(assignment_id)

    %{
      title: dgettext("eyra-nextaction", "assignment.pending_contributions.title"),
      description: build_description(name),
      cta_label: dgettext("eyra-nextaction", "assignment.pending_contributions.cta"),
      cta_action: %{
        type: :redirect,
        to: ~p"/assignment/#{assignment_id}/content?tab=contributions"
      }
    }
  end

  defp resolve_assignment_name(assignment_id) do
    case Repo.get(Assignment.Model, assignment_id) |> Repo.preload(:project_item) do
      %{project_item: %{name: name}} when is_binary(name) and name != "" -> name
      _ -> "assignment ##{assignment_id}"
    end
  end

  defp build_description(name) do
    dgettext("eyra-nextaction", "assignment.pending_contributions.description", name: name)
    |> truncate(@max_description_length)
  end

  defp truncate(str, max_len) do
    if String.length(str) <= max_len,
      do: str,
      else: String.slice(str, 0, max_len - 1) <> "…"
  end
end
