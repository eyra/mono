defmodule Systems.Graphite.LeaderboardSubmissionsForm do
  use CoreWeb.LiveForm

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
      |> prepare_download_button()
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form id="select_file_form" for={%{}} phx-change="change" phx-target="" >
        <div class="flex flex-row items-center">
          <Text.title2 margin="mb-0">
            <%= dgettext("eyra-graphite","tabbar.item.submissions.title") %>
            <span class="text-primary"> <%= Enum.count(@submissions) %></span>
          </Text.title2>
          <div class="flex-grow" />
          <div>
            <Button.dynamic {@download_button} />
          </div>
        </div>
        <%= if length(@submissions) > 0 do %>
          <.spacing value="L" />
          <.submission_list submissions={@submissions} />
        <% end %>
      </.form>
    </div>
    """
  end

  attr(:submissions, :list, required: true)

  defp submission_list(assigns) do
    ~H"""
      <%= if Enum.count(@submissions) > 0 do %>
        <table>
          <thead>
            <tr>
              <th class="pl-0"><Text.title6 align="text-left"><%= dgettext("eyra-graphite","submission.list.header.number") %></Text.title6></th>
              <th class="pl-8"><Text.title6 align="text-left"><%= dgettext("eyra-graphite","submission.list.header.description") %></Text.title6></th>
              <th class="pl-8"><Text.title6 align="text-left"><%= dgettext("eyra-graphite","submission.list.header.link") %></Text.title6></th>
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
          <a class="text-primary underline" target="_blank" href={@github_commit_url}>Link</a>
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
      face: %{
        type: :label,
        label: dgettext("eyra-graphite", "export.submissions.button"),
        icon: :export
      }
    }

    assign(socket, download_button: download_button)
  end
end
