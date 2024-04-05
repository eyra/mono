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
        berakpoint: breakpoint,
        placeholder: "Upload file",
        select_button: "Select file",
        replace_button: "Replace file",
        csv_local_path: nil,
        csv_remote_file: nil,
        csv_lines: nil
      )
    }
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
        </div>
      </.form>
    </div>
    """
  end
end
