defmodule Systems.Pool.DashboardView do
  use CoreWeb.UI.LiveComponent

  alias Frameworks.Pixel.Text.{Title2}
  alias Frameworks.Pixel.Widget.{Metric, ValueDistribution, Progress}

  prop(props, :map, required: true)

  data(years, :map)

  def update(%{props: %{years: years}} = _params, socket) do
    {
      :ok,
      socket |> assign(years: years)
    }
  end

  def render(assigns) do
    ~F"""
    <ContentArea>
      <MarginY id={:page_top} />
      <div :for={year <- @years}>
        <Title2>{year.title}</Title2>
        <div class="grid grid-cols-2 md:grid-cols-3 gap-8 h-full">
          <div :for={metric <- year.metrics}>
            <Metric {...metric} />
          </div>
          <div class="col-span-3">
            <ValueDistribution {...year.credits} />
          </div>
          <div class="col-span-3">
            <Progress {...year.progress} />
          </div>
        </div>
        <Spacing value="XXL" />
      </div>
    </ContentArea>
    """
  end
end
