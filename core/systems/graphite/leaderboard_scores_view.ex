defmodule Systems.Graphite.LeaderboardScoresView do
  use CoreWeb, :live_component

  alias Systems.{
    Graphite
  }

  @impl true
  def update(
        %{
          id: id,
          entity: leaderboard
        },
        socket
      ) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        leaderboard: leaderboard
      )
      |> compose_child(:upload)
    }
  end

  @impl true
  def compose(:upload, %{
        leaderboard: leaderboard
      }) do
    %{
      module: Graphite.LeaderboardScoresForm,
      params: %{
        leaderboard: leaderboard,
        page_key: :upload,
        opt_in?: false,
        on_text: "upload view on text",
        off_text: "upload view off text"
      }
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
        <Margin.y id={:page_top} />
        <.child name={:upload} fabric={@fabric} >
          <:header>
            <Text.title2><%= dgettext("eyra-graphite", "tabbar.item.scores") %></Text.title2>
          </:header>
          <:footer>
          </:footer>
        </.child>
      </Area.content>
    </div>
    """
  end
end
