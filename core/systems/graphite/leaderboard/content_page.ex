defmodule Systems.Graphite.Leaderboard.ContentPage do
  use CoreWeb, :live_view_fabric
  use Fabric.LiveView, CoreWeb.Layouts
  use Systems.Content.Page

  alias Systems.{
    Graphite
  }

  @impl true
  def get_authorization_context(%{"leaderboard_id" => id}, _session, _socket) do
    # FIXME JAN
    # not sure what authorization context is actually needed here
    Graphite.Public.get_leaderboard!(String.to_integer(id))
  end

  @impl true
  def mount(%{"leaderboard_id" => id} = params, _, socket) do
    initial_tab = Map.get(params, "tab")

    model =
      Graphite.Public.get_leaderboard!(
        String.to_integer(id),
        Graphite.LeaderboardModel.preload_graph(:down)
      )

    tabbar_id = "leaderboard_content/#{id}"

    {
      :ok,
      socket
      |> initialize(id, model, tabbar_id, initial_tab)
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.content_page
      actions={@actions}
      title={@vm.title}
      show_errors={@vm.show_errors}
      tabs={@vm.tabs}
      menus={@menus}
      initial_tab={@initial_tab}
      tabbar_id={@tabbar_id}
      tabbar_size={@tabbar_size}
      breakpoint={@breakpoint}
      popup={@popup}
      dialog={@dialog}
    />
    """
  end
end
