defmodule Systems.Graphite.LeaderboardPage do
  use CoreWeb, :live_view_fabric
  use Fabric.LiveView, CoreWeb.Layouts
  use Systems.Observatory.Public

  use CoreWeb.Layouts.Stripped.Component, :leaderboard

  alias Frameworks.Pixel.Align

  alias Systems.Graphite

  @impl true
  def get_authorization_context(%{"id" => leaderboard_id}, _session, _socket) do
    Graphite.Public.get_leaderboard!(String.to_integer(leaderboard_id), [:auth_node])
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    model =
      Graphite.Public.get_leaderboard!(
        String.to_integer(id),
        Graphite.LeaderboardModel.preload_graph(:down)
      )

    {
      :ok,
      socket
      |> assign(model: model)
      |> observe_view_model()
      |> compose_child(:leaderboard_table)
    }
  end

  def handle_view_model_updated(socket) do
    socket |> compose_child(:leaderboard_table)
  end

  @impl true
  def compose(:leaderboard_table, %{vm: %{leaderboard_table: leaderboard_table}}) do
    leaderboard_table
  end

  @impl true
  def handle_event(_, _payload, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <.stripped title={dgettext("eyra-graphite", "leaderboard.title")} menus={@menus}>
        <Area.content>
          <Margin.y id={:page_top} />
          <Align.horizontal_center>
             <Text.title2><%= @vm.title %></Text.title2>
          </Align.horizontal_center>
          <.spacing value="M" />
          <.stack fabric={@fabric} />
        </Area.content>
      </.stripped>
    """
  end
end
