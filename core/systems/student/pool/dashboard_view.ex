defmodule Systems.Student.Pool.DashboardView do
  use CoreWeb, :live_component

  alias Frameworks.Pixel.Widget

  @impl true
  def update(
        %{metrics: metrics, credits: credits, progress: progress} = _params,
        socket
      ) do
    {
      :ok,
      socket
      |> assign(
        metrics: metrics,
        credits: credits,
        progress: progress
      )
    }
  end

  attr(:metrics, :map, required: true)
  attr(:credits, :map, required: true)
  attr(:progress, :map, required: true)
  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
      <Margin.y id={:page_top} />
      <div class="grid grid-cols-2 md:grid-cols-3 gap-8 h-full">
        <%= for metric <- @metrics do %>
          <Widget.metric {metric} />
        <% end %>
        <div class="col-span-3">
          <Widget.value_distribution {@credits} />
        </div>
        <div class="col-span-3">
          <Widget.progress {@progress} />
        </div>
      </div>
      </Area.content>
    </div>
    """
  end
end
