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
        <Text.title2><%= dgettext("eyra-storage", "tabbar.item.data") %></Text.title2>
        <.spacing value="L" />
        <Html.files_table files={@files} />
      </Area.content>
    </div>
    """
  end
end
