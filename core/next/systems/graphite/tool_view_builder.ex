defmodule Systems.Graphite.ToolViewBuilder do
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Graphite

  @doc """
  Builds view model for Graphite tool view.

  ## Parameters
  - tool: The Graphite tool model
  - assigns: Contains current_user and timezone from CrewTaskContext
  """
  def view_model(tool, %{current_user: user, timezone: timezone}) do
    submission = Graphite.Public.get_submission(tool, user, :owner)
    open_for_submissions? = Graphite.Public.open_for_submissions?(tool)

    %{
      tool: tool,
      submission: submission,
      open_for_submissions?: open_for_submissions?,
      leaderboard_description: dgettext("eyra-graphite", "leaderboard.description"),
      leaderboard_button: build_leaderboard_button(tool, open_for_submissions?),
      done_button: build_done_button(),
      submission_form: build_submission_form(tool, user, open_for_submissions?, timezone)
    }
  end

  defp build_leaderboard_button(
         %{leaderboard: %{status: :online, id: leaderboard_id}},
         false = _open_for_submissions?
       ) do
    %{
      action: %{
        type: :http_get,
        to: "/graphite/leaderboard/#{leaderboard_id}",
        target: "_blank"
      },
      face: %{
        type: :plain,
        icon: :forward,
        label: dgettext("eyra-graphite", "leaderboard.goto.button")
      }
    }
  end

  defp build_leaderboard_button(_tool, _open_for_submissions?), do: nil

  defp build_done_button do
    %{
      action: %{type: :send, event: "done"},
      face: %{type: :primary, label: dgettext("eyra-ui", "done.button")}
    }
  end

  defp build_submission_form(tool, user, open_for_submissions?, timezone) do
    %{
      module: Graphite.SubmissionForm,
      id: :submission_form,
      tool: tool,
      user: user,
      open?: open_for_submissions?,
      timezone: timezone
    }
  end
end
