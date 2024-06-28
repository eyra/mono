defmodule Systems.Storage.EndpointDataView do
  use CoreWeb, :live_component

  alias Systems.Storage.Html

  @impl true
  def update(%{endpoint: endpoint, files: files}, %{assigns: %{}} = socket) do
    {
      :ok,
      socket
      |> assign(
        endpoint: endpoint,
        files: files
      )
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
        <Margin.y id={:page_top} />
        <Text.title2><%= dgettext("eyra-storage", "tabbar.item.data") %> <span class="text-primary"><%= Enum.count(@files) %></span></Text.title2>
        <%= if not Enum.empty?(@files) do %>
          <.spacing value="L" />
          <Html.files_table files={@files} />
        <% end %>
      </Area.content>
    </div>
    """
  end
end
