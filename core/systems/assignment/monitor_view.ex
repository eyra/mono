defmodule Systems.Assignment.MonitorView do
  use CoreWeb, :live_component

  alias Frameworks.Pixel.Widget

  @impl true
  def update(%{number_widgets: number_widgets, progress_widgets: progress_widgets}, socket) do
    {
      :ok,
      socket
      |> assign(
        number_widgets: number_widgets,
        progress_widgets: progress_widgets
      )
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <Area.content>
          <Margin.y id={:page_top} />
          <Text.title2><%= dgettext("eyra-assignment", "monitor.title") %></Text.title2>
          <.spacing value="L" />
          <div class="grid grid-cols-3 gap-12 h-full">
            <%= for widget <- @number_widgets do %>
              <Widget.number {widget} />
            <% end %>
            <%= for widget <- @progress_widgets do %>
              <div class="col-span-3">
                <Widget.progress {widget} />
              </div>
            <% end %>
          </div>
        </Area.content>
      </div>
    """
  end
end
