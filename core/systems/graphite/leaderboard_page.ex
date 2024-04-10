defmodule Systems.Graphite.LeaderboardPage do
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Stripped.Component, :onboarding

  alias Frameworks.Pixel.Align

  alias Systems.{
    Graphite
  }

  @impl true
  def get_authorization_context(%{"leaderboard_id" => leaderboard_id}, _session, _socket) do
    Graphite.Public.get_leaderboard!(String.to_integer(leaderboard_id))
  end

  def mount(%{"leaderboard_id" => leaderboard_id}, _session, socket) do
    {
      :ok,
      socket
      |> assign(leaderboard_id: leaderboard_id)
      |> update_leaderboard()
      |> update_title()
    }
  end

  defp update_title(%{assigns: %{leaderboard: leaderboard}} = socket) do
    assign(socket, title: leaderboard.name)
  end

  defp update_leaderboard(%{assigns: %{leaderboard_id: leaderboard_id}} = socket) do
    leaderboard =
      Graphite.Public.get_leaderboard!(leaderboard_id, [:auth_node, :tool, {:scores, :submission}])

    categories = group_scores(leaderboard)

    leaderboard_live = %{
      id: :leaderboard_live,
      open: information_open?(leaderboard.open_date),
      categories: categories,
      module: Graphite.LeaderboardView
    }

    assign(socket, leaderboard: leaderboard, leaderboard_live: leaderboard_live)
  end

  defp information_open?(nil), do: true

  defp information_open?(datetime) do
    NaiveDateTime.diff(datetime, NaiveDateTime.local_now()) > 0
  end

  defp group_scores(leaderboard) do
    Enum.map(
      leaderboard.metrics,
      fn metric ->
        %{
          name: metric,
          scores: leaderboard.scores |> Enum.filter(&(&1.metric == metric))
        }
      end
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
      <.stripped title="Leaderboard" menus={@menus}>
        <Area.content>
          <Margin.y id={:page_top} />
          <Align.horizontal_center>
             <Text.title2><%= @title %></Text.title2>
          </Align.horizontal_center>
          <.spacing value="M" />
          <.live_component {@leaderboard_live} />
          <.spacing value="XL" />
        </Area.content>
      </.stripped>
    """
  end
end
