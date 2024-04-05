defmodule Systems.Graphite.LeaderboardDownloadForm do
  use CoreWeb.LiveForm, :fabric
  use Fabric.LiveComponent

  alias Frameworks.Pixel.Text

  @impl true
  def update(
        %{
          id: id,
          leaderboard: leaderboard,
          uri_origin: uri_origin,
          viewport: viewport,
          breakpoint: breakpoint
        },
        socket
      ) do
    columns = ["submission" | leaderboard.metrics]

    {
      :ok,
      socket
      |> assign(
        id: id,
        columns: columns,
        leaderboard: leaderboard,
        uri_origin: uri_origin,
        viewport: viewport,
        berakpoint: breakpoint
      )
      |> prepare_download_button("Download")
    }
  end

  defp prepare_download_button(socket, label) do
    download_button = %{
      action: %{type: :send, event: "download"},
      face: %{type: :primary, label: label}
    }

    assign(socket, download_button: download_button)
  end

  @impl true
  def handle_event("download", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form id="select_file_form" for={%{}} phx-change="change" phx-target="" >
        <div>
          <.spacing value="L" />
          <Text.title2>Download submission details</Text.title2>
          <Text.body_medium>Info on current submissions  here</Text.body_medium>
          <Text.body_medium>Also: download button</Text.body_medium>

          <Button.dynamic {@download_button} />
        </div>
      </.form>
    </div>
    """
  end
end
