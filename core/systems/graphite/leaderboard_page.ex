defmodule Systems.Graphite.LeaderboardPage do
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Stripped.Component, :onboarding

  alias Frameworks.Pixel.Align

  alias Systems.{
    Graphite
  }

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {
      :ok,
      socket
      |> assign(id: id)
      |> update_title()
      |> update_leaderboard()
      |> update_forward_button()
    }
  end

  defp update_title(%{assigns: %{id: tool_id}} = socket) do
    %{title: title} = Graphite.Public.get_tool!(tool_id)
    assign(socket, title: title)
  end

  defp update_forward_button(%{assigns: %{id: tool_id}} = socket) do
    forward_button = %{
      action: %{type: :http_get, to: ~p"/graphite/#{tool_id}"},
      face: %{
        type: :plain,
        label: dgettext("eyra-benchmark", "challenge.forward.button"),
        icon: :forward
      }
    }

    assign(socket, forward_button: forward_button)
  end

  defp update_leaderboard(%{assigns: %{id: tool_id}} = socket) do
    categories =
      Graphite.Public.list_leaderboard_categories(tool_id, scores: [submission: [:spot]])

    leaderboard = %{
      id: :leaderboard,
      module: Graphite.LeaderboardView,
      categories: categories
    }

    assign(socket, leaderboard: leaderboard)
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
          <.live_component {@leaderboard} />
          <.spacing value="XL" />
          <Button.dynamic {@forward_button} />
        </Area.content>
      </.stripped>
    """
  end
end
