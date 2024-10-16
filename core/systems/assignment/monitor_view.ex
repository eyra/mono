defmodule Systems.Assignment.MonitorView do
  use CoreWeb, :live_component

  alias Frameworks.Pixel.Widget

  @impl true
  def update(
        %{
          assignment: assignment,
          number_widgets: number_widgets,
          progress_widgets: progress_widgets
        },
        socket
      ) do
    {
      :ok,
      socket
      |> assign(
        assignment: assignment,
        number_widgets: number_widgets,
        progress_widgets: progress_widgets
      )
      |> update_export_button()
    }
  end

  defp update_export_button(%{assigns: %{assignment: %{id: id}}} = socket) do
    export_button = %{
      action: %{
        type: :http_download,
        to: ~p"/assignment/#{id}/export"
      },
      face: %{
        type: :label,
        label: dgettext("eyra-assignment", "export.progress.button"),
        icon: :export
      }
    }

    assign(socket, export_button: export_button)
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <Area.content>
          <Margin.y id={:page_top} />
          <div class="flex flex-row items-top">
            <Text.title2><%= dgettext("eyra-assignment", "monitor.title") %></Text.title2>
            <div class="flex-grow" />
            <Button.dynamic {@export_button} />
          </div>

          <Text.body><%= dgettext("eyra-assignment", "monitor.description") %></Text.body>
          <.spacing value="M" />
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
