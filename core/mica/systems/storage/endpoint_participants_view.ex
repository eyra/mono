defmodule Systems.Storage.EndpointParticipantsView do
  use CoreWeb, :live_component_fabric

  alias CoreWeb.UI.Timestamp
  alias Systems.Storage

  @impl true
  def update(%{endpoint: endpoint, timezone: timezone}, socket) do
    participants =
      endpoint
      |> Storage.Public.list_files()
      |> Storage.Donations.summaries()
      |> Enum.map(&stamp_last_donation(&1, timezone))

    {:ok, socket |> assign(endpoint: endpoint, participants: participants)}
  end

  defp stamp_last_donation(%{last_donation: nil} = summary, _timezone), do: summary

  defp stamp_last_donation(%{last_donation: last_donation} = summary, timezone) do
    %{summary | last_donation: last_donation |> Timestamp.convert(timezone) |> Timestamp.stamp()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div data-testid="participants-view">
      <Area.content>
        <Margin.y id={:page_top} />
        <div class="flex flex-row items-center gap-3">
          <Text.title2 margin=""><%= dgettext("eyra-storage", "tabbar.item.participants") %></Text.title2>
          <Text.title2 margin=""><span class="text-primary"><%= Enum.count(@participants) %></span></Text.title2>
        </div>
        <.spacing value="M" />
        <%= if Enum.empty?(@participants) do %>
          <Text.body_large><%= dgettext("eyra-storage", "participants.empty.description") %></Text.body_large>
        <% else %>
          <Text.body_large><%= dgettext("eyra-storage", "participants.description") %></Text.body_large>
          <.spacing value="M" />
          <Storage.Html.participants_table participants={@participants} />
        <% end %>
      </Area.content>
    </div>
    """
  end
end
