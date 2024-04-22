defmodule Systems.Graphite.LeaderboardDownloadView do
  use CoreWeb, :live_component_fabric
  use Fabric.LiveComponent

  alias Systems.Graphite

  @impl true
  def update(
        %{
          id: id,
          entity: leaderboard,
          uri_origin: uri_origin,
          viewport: viewport,
          breakpoint: breakpoint
        },
        socket
      ) do
    submissions = Graphite.Public.list_submissions(leaderboard)

    {
      :ok,
      socket
      |> assign(
        id: id,
        leaderboard: leaderboard,
        submissions: submissions,
        uri_origin: uri_origin,
        viewport: viewport,
        breakpoint: breakpoint
      )
      |> compose_child(:download)
    }
  end

  @impl true
  def compose(:download, %{
        leaderboard: leaderboard,
        submissions: submissions,
        uri_origin: uri_origin,
        viewport: viewport,
        breakpoint: breakpoint
      }) do
    %{
      module: Graphite.LeaderboardDownloadForm,
      params: %{
        leaderboard: leaderboard,
        submissions: submissions,
        uri_origin: uri_origin,
        viewport: viewport,
        breakpoint: breakpoint,
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
