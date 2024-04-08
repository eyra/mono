defmodule Systems.Graphite.LeaderboardUploadView do
  use CoreWeb, :live_component_fabric
  use Fabric.LiveComponent

  alias Systems.{
    Graphite
  }

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
    {
      :ok,
      socket
      |> assign(
        id: id,
        leaderboard: leaderboard,
        uri_origin: uri_origin,
        viewport: viewport,
        breakpoint: breakpoint
      )
      |> compose_child(:upload)
    }
  end

  @impl true
  def compose(:upload, %{
        leaderboard: leaderboard,
        uri_origin: uri_origin,
        viewport: viewport,
        breakpoint: breakpoint
      }) do
    %{
      module: Graphite.LeaderboardUploadForm,
      params: %{
        leaderboard: leaderboard,
        uri_origin: uri_origin,
        viewport: viewport,
        breakpoint: breakpoint,
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
        <.child name={:upload} fabric={@fabric} >
          <:header>
          </:header>
          <:footer>
            <.spacing value="L" />
          </:footer>
        </.child>
      </Area.content>
    </div>
    """
  end
end
