defmodule Systems.Graphite.LeaderboardPage do
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Stripped.Component, :onboarding

  alias Frameworks.Pixel.Align

  alias Systems.{
    Assignment,
    Graphite
  }

  @impl true
  def get_authorization_context(%{"id" => leaderboard_id}, _session, _socket) do
    Graphite.Public.get_leaderboard!(String.to_integer(leaderboard_id))
  end

  def mount(%{"id" => leaderboard_id}, _session, socket) do
    {
      :ok,
      socket
      |> assign(leaderboard_id: leaderboard_id)
      |> update_leaderboard()
      |> update_assignment()
      |> update_title()
      |> check_access()
    }
  end

  defp update_assignment(%{assigns: %{leaderboard: leaderboard}} = socket) do
    assignment = Assignment.Public.get_by_tool(leaderboard.tool, [:info, :crew, :auth_node])
    assign(socket, :assignment, assignment)
  end

  defp check_access(%{assigns: %{leaderboard: leaderboard, assignment: assignment}} = socket) do
    cond do
      leaderboard.status == :online -> assign(socket, :show, :ok)
      tester?(assignment, socket) -> assign(socket, :show, :ok)
      true -> assign(socket, :show, :forbidden)
    end
  end

  defp tester?(assignment, %{assigns: %{current_user: %{} = user}}) do
    Assignment.Public.tester?(assignment, user)
  end

  defp tester?(_, _), do: false

  defp update_title(%{assigns: %{leaderboard: leaderboard}} = socket) do
    assign(socket, title: leaderboard.title)
  end

  defp update_leaderboard(
         %{assigns: %{leaderboard_id: leaderboard_id, current_user: _user}} = socket
       ) do
    leaderboard =
      Graphite.Public.get_leaderboard!(leaderboard_id, [:auth_node, :tool, {:scores, :submission}])

    categories = group_scores(leaderboard)

    leaderboard_live = %{
      id: :leaderboard_live,
      open: information_open?(leaderboard.open_date),
      categories: categories,
      leaderboard: leaderboard,
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
          scores:
            leaderboard.scores
            |> Enum.filter(&(&1.metric == metric))
            |> Enum.sort(&(&1.score < &2.score))
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
          <%= if @show == :ok do %>
            <.live_component {@leaderboard_live} />
          <% else %>
            Forbidden
          <% end %>
          <.spacing value="XL" />
        </Area.content>
      </.stripped>
    """
  end
end
