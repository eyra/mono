defmodule Systems.Graphite.LeaderboardDownloadForm do
  use CoreWeb.LiveForm, :fabric
  use Fabric.LiveComponent

  alias Frameworks.Pixel.Text

  @impl true
  def update(
        %{
          id: id,
          leaderboard: leaderboard,
          submissions: submissions,
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
        submissions: submissions,
        uri_origin: uri_origin,
        viewport: viewport,
        breakpoint: breakpoint
      )
      |> prepare_download_button()
    }
  end

  @impl true
  def handle_event("download", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div>
        <.submission_list submissions={@submissions} />
      </div>
      <.form id="select_file_form" for={%{}} phx-change="change" phx-target="" >
        <div>
          <.spacing value="L" />
          <Button.dynamic {@download_button} />
        </div>
      </.form>
    </div>
    """
  end

  attr(:submissions, :list, required: true)

  defp submission_list(assigns) do
    ~H"""
      <%= if Enum.count(@submissions) > 0 do %>
        <.spacing value="L" />
        <Text.title2>Current submissions</Text.title2>
        <table>
          <thead>
            <tr>
              <th class="pl-0"><Text.title6>Number</Text.title6></th>
              <th class="pl-8"><Text.title6>Description</Text.title6></th>
              <th class="pl-8"><Text.title6>Link</Text.title6></th>
            </tr>
          </thead>
          <tbody>
            <%= for {submission, nr} <- Enum.with_index(@submissions, 1) do %>
              <.item { Map.from_struct(submission) |> Map.put(:nr, nr) } />
            <% end %>
          </tbody>
        </table>
      <% end %>
    """
  end

  attr(:description, :string, required: true)
  attr(:team, :string, default: nil)
  attr(:summary, :string, required: true)
  attr(:url, :string, required: true)
  attr(:buttons, :list, required: true)

  defp item(assigns) do
    ~H"""
    <tr class="h-12">
      <td class="pl-0">
        <Text.body_medium><%= @nr %></Text.body_medium>
      </td>
      <td class="pl-8">
        <Text.body_medium><%= @description %></Text.body_medium>
      </td>
      <td class="pl-8">
        <Text.body_medium>
          <a class="text-primary underline" target="_blank" href={@github_commit_url}>Github</a>
        </Text.body_medium>
      </td>
    </tr>
    """
  end

  defp prepare_download_button(%{assigns: %{leaderboard: %{id: id}}} = socket) do
    download_button = %{
      action: %{
        type: :http_get,
        to: ~p"/graphite/#{id}/export/submissions",
        target: "_blank"
      },
      face: %{type: :label, label: "Export", icon: :export}
    }

    assign(socket, download_button: download_button)
  end
end
