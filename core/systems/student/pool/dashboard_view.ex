defmodule Systems.Student.Pool.DashboardView do
  use CoreWeb.UI.LiveComponent

  alias Frameworks.Pixel.Widget.{Metric, ValueDistribution, Progress}

  prop(props, :map, required: true)

  data(metrics, :list)
  data(credits, :map)
  data(progress, :map)

  def update(
        %{props: %{metrics: metrics, credits: credits, progress: progress}} = _params,
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

  def render(assigns) do
    ~F"""
    <ContentArea>
      <MarginY id={:page_top} />
      <div class="grid grid-cols-2 md:grid-cols-3 gap-8 h-full">
        <div :for={metric <- @metrics}>
          <Metric {...metric} />
        </div>
        <div class="col-span-3">
          <ValueDistribution {...@credits} />
        </div>
        <div class="col-span-3">
          <Progress {...@progress} />
        </div>
      </div>
    </ContentArea>
    """
  end
end
