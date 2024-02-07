defmodule Systems.Assignment.MonitorView do
  use CoreWeb, :live_component_fabric
  use Fabric.LiveComponent

  alias Frameworks.Pixel.Widget
  alias Systems.Assignment

  @impl true
  def update(%{assignment: assignment}, socket) do
    {
      :ok,
      socket
      |> assign(assignment: assignment)
      |> update_metrics()
    }
  end

  defp update_metrics(%{assigns: %{assignment: assignment}} = socket) do
    metrics =
      [:started, :finished]
      |> Enum.map(&metric(&1, assignment))

    socket
    |> assign(metrics: metrics)
  end

  defp metric(:started, assignment) do
    %{
      label: dgettext("eyra-assignment", "started.participants"),
      number: Assignment.Public.count_participants(assignment),
      color: :primary
    }
  end

  defp metric(:finished, assignment) do
    %{
      label: dgettext("eyra-assignment", "finished.participants"),
      number: Assignment.Public.count_participants_finished(assignment),
      color: :positive
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
          <div class="grid grid-cols-3 gap-8 h-full">
            <%= for metric <- @metrics do %>
              <Widget.metric {metric} />
            <% end %>
          </div>
        </Area.content>
      </div>
    """
  end
end
