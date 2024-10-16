defmodule Systems.Graphite.LeaderboardScoreHTML do
  use CoreWeb, :html

  import Frameworks.Pixel.Table

  attr(:scores, :list, required: true)

  def html(%{scores: scores} = assigns) do
    head_cells = [
      dgettext("eyra-graphite", "leaderboard.position.label"),
      dgettext("eyra-graphite", "leaderboard.team.label"),
      dgettext("eyra-graphite", "leaderboard.method.label"),
      dgettext("eyra-graphite", "leaderboard.github.label"),
      dgettext("eyra-graphite", "leaderboard.score.label")
    ]

    layout = [
      %{type: :text, width: "w-24", align: "text-left"},
      %{type: :text, width: "flex-1", align: "text-left"},
      %{type: :text, width: "flex-1", align: "text-left"},
      %{type: :href, width: "w-28", align: "text-center"},
      %{type: :text, width: "w-24", align: "text-right"}
    ]

    rows =
      scores
      |> Enum.with_index()
      |> Enum.map(fn {%{team: team, description: description, url: url, value: value}, index} ->
        [index + 1, team, description, url, value]
      end)

    assigns = assign(assigns, head_cells: head_cells, layout: layout, rows: rows)

    ~H"""
      <.table layout={@layout} head_cells={@head_cells} rows={@rows} />
    """
  end
end
