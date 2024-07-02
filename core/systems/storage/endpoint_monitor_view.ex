defmodule Systems.Storage.EndpointMonitorView do
  use CoreWeb, :live_component

  alias Frameworks.Pixel.Widget

  @impl true
  def update(%{number_widgets: number_widgets}, socket) do
    {
      :ok,
      socket
      |> assign(number_widgets: number_widgets)
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <Area.content>
          <Margin.y id={:page_top} />
          <Text.title2><%= dgettext("eyra-storage", "tabbar.item.monitor") %></Text.title2>
          <.spacing value="L" />
          <div class="grid grid-cols-3 gap-12 h-full">
            <%= for widget <- @number_widgets do %>
              <Widget.number {widget} />
            <% end %>
          </div>
        </Area.content>
      </div>
    """
  end
end
