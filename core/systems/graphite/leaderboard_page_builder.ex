defmodule Systems.Graphite.LeaderboardPageBuilder do
  use CoreWeb, :verified_routes

  import CoreWeb.Gettext

  alias CoreWeb.UI.Timestamp
  alias Core.Accounts.User
  alias Systems.Graphite

  def view_model(
        %Graphite.LeaderboardModel{id: id, title: title, metrics: metrics} = leaderboard,
        %{current_user: user} = _assigns
      ) do
    leaderboard =
      Core.Repo.preload(
        leaderboard,
        [
          scores: [Graphite.ScoreModel.preload_graph(:down)],
          tool: [:submissions]
        ],
        force: true
      )

    online? = Graphite.LeaderboardModel.online?(leaderboard)
    owner? = Core.Authorization.roles_intersect?(user, leaderboard, [:owner])

    %{info: info} = Graphite.Public.get_challenge(leaderboard, [:info])

    if online? or owner? do
      %{
        id: id,
        title: title,
        info: info,
        highlights: highlights(leaderboard),
        leaderboard_table: %{
          module: Graphite.LeaderboardTableView,
          params: %{
            metrics: metrics,
            metric_scores: map_metrics_to_scores(leaderboard, user, owner?)
          }
        }
      }
    else
      %{
        id: id,
        title: dgettext("eyra-graphite", "leaderboard.offline.title"),
        info: info,
        leaderboard_table: nil
      }
    end
  end

  defp highlights(leaderboard) do
    [
      :submissions,
      :generated_on,
      :visibility
    ]
    |> Enum.map(&highlight(leaderboard, &1))
  end

  defp highlight(%Graphite.LeaderboardModel{tool: %{submissions: submissions}}, :submissions) do
    %{
      title: dgettext("eyra-graphite", "highlight.submissions.title"),
      text:
        dgettext("eyra-graphite", "highlight.submissions.text", count: Enum.count(submissions))
    }
  end

  defp highlight(%Graphite.LeaderboardModel{generation_date: nil}, :generated_on) do
    %{
      title: dgettext("eyra-graphite", "highlight.generated_on.title"),
      text: "?"
    }
  end

  defp highlight(%Graphite.LeaderboardModel{generation_date: generation_date}, :generated_on) do
    datestamp = Timestamp.format_date!(generation_date)

    %{
      title: dgettext("eyra-graphite", "highlight.generated_on.title"),
      text: dgettext("eyra-graphite", "highlight.generated_on.text", date: datestamp)
    }
  end

  defp highlight(%Graphite.LeaderboardModel{visibility: :private}, :visibility) do
    %{
      title: dgettext("eyra-graphite", "highlight.visibility.title"),
      text: dgettext("eyra-graphite", "highlight.visibility.private.text")
    }
  end

  defp highlight(%Graphite.LeaderboardModel{visibility: :public}, :visibility) do
    %{
      title: dgettext("eyra-graphite", "highlight.visibility.title"),
      text: dgettext("eyra-graphite", "highlight.visibility.public.text")
    }
  end

  defp map_metrics_to_scores(
         %Graphite.LeaderboardModel{metrics: metrics, scores: scores, visibility: visibility} =
           leaderboard,
         user,
         owner?
       ) do
    participants = participants(leaderboard)

    Enum.reduce(metrics, %{}, fn metric, acc ->
      Map.put(
        acc,
        metric,
        scores_for_metric(scores, metric, participants, user, owner?, visibility)
      )
    end)
  end

  defp scores_for_metric(scores, metric, participants, user, owner?, visibility) do
    scores
    |> Enum.filter(&(&1.metric == metric))
    |> Enum.sort_by(& &1.score, :desc)
    |> Enum.map(&score_vm(&1, participants, user, owner?, visibility))
  end

  defp score_vm(%{id: id} = score, participants, user, owner?, visibility) do
    team = get_team(participants, score)
    description = get_description(score)
    url = get_url(score)
    value = get_value(score)

    anonymize? = anonymize?(user, owner?, visibility, score)

    %{
      id: id,
      team: anonymize(team, anonymize?),
      description: anonymize(description, anonymize?),
      url: anonymize(url, anonymize?),
      value: value
    }
  end

  defp get_team(participants, %{
         submission: %{auth_node: %{role_assignments: [%{principal_id: principal_id} | _]}}
       }) do
    Map.get(participants, principal_id, "Unknown")
  end

  defp get_url(%{submission: %{github_commit_url: url}}), do: url
  defp get_description(%{submission: %{description: description}}), do: description
  defp get_value(%{score: value}), do: trunc(value * 1_000_000) / 1_000_000

  defp anonymize?(_, true, _, _), do: false

  defp anonymize?(%{id: user_id}, _, visibility, %{
         submission: %{auth_node: %{role_assignments: [%{principal_id: principal_id} | _]}}
       }) do
    principal_id != user_id and visibility == :private
  end

  defp anonymize(_, true), do: dgettext("eyra-graphite", "anonymous.label")
  defp anonymize(string, _), do: string

  defp participants(%Graphite.LeaderboardModel{} = leaderboard) do
    Graphite.Public.get_participants(leaderboard)
    |> Enum.reduce(%{}, fn participant, acc ->
      Map.put(acc, participant.id, User.label(participant))
    end)
  end
end
