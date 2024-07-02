defmodule Systems.Storage.EndpointMonitorView do
  use CoreWeb, :live_component

  @impl true
  def update(%{endpoint: endpoint}, %{assigns: %{}} = socket) do
    {
      :ok,
      socket
      |> assign(endpoint: endpoint)
    }
  end

  @impl true
  def handle_event("update", _payload, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
        <Margin.y id={:page_top} />
        <Text.title2><%= dgettext("eyra-storage", "tabbar.item.monitor") %></Text.title2>
        <.spacing value="L" />
      </Area.content>
    </div>
    """
  end
end
