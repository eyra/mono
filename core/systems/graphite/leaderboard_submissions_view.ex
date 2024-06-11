defmodule Systems.Graphite.LeaderboardSubmissionsView do
  use CoreWeb, :live_component

  alias Systems.Graphite

  @impl true
  def update(
        %{
          id: id,
          entity: leaderboard,
          submissions: submissions
        },
        socket
      ) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        leaderboard: leaderboard,
        submissions: submissions
      )
      |> compose_child(:download)
    }
  end

  @impl true
  def compose(:download, %{
        leaderboard: leaderboard,
        submissions: submissions
      }) do
    %{
      module: Graphite.LeaderboardSubmissionsForm,
      params: %{
        leaderboard: leaderboard,
        submissions: submissions,
        page_key: :upload,
        opt_in?: false,
        on_text: "download view on text",
        off_text: "download view off text"
      }
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
        <Margin.y id={:page_top} />
        <.child name={:download} fabric={@fabric} />
      </Area.content>
    </div>
    """
  end
end
