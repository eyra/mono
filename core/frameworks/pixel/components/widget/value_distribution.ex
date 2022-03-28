defmodule Frameworks.Pixel.Widget.ValueDistribution do
  use Frameworks.Pixel.Component

  @bar_height 200

  prop(scale, :integer, required: true)
  prop(values, :list, required: true)

  defp bars(_scale, []), do: []

  defp bars(scale, values) do
    max = Statistics.max(values)
    count = Integer.floor_div(max, scale)

    value_count_list =
      Enum.to_list(0..count)
      |> Enum.map(&value_count(&1, scale, values))

    max_value_count =
      value_count_list
      |> Statistics.max()

    value_count_list
    |> Enum.with_index()
    |> Enum.map(fn {value_count, index} ->
      %{
        range: range_label(index, scale),
        value_count: value_count,
        height: value_count / max_value_count
      }
    end)
  end

  defp range_label(index, scale) do
    {from, to} = range(index, scale)

    if from == to - 1 do
      "#{from}"
    else
      "#{from} - #{to - 1}"
    end
  end

  defp range(index, scale) do
    {index * scale, (index + 1) * scale}
  end

  defp value_count(index, scale, values) do
    {from, to} = range(index, scale)
    values |> Enum.filter(&(&1 >= from and &1 < to)) |> Enum.count()
  end

  defp bar_top_height(%{value_count: 0}), do: @bar_height - 2
  defp bar_top_height(bar), do: @bar_height - bar_height(bar)

  defp bar_height(%{value_count: 0}), do: 0
  defp bar_height(%{height: height}), do: max(ceil(@bar_height * height), 4)

  defp bar_width(scale, values) do
    bar_width = floor(100 / Enum.count(bars(scale, values)))
    "#{bar_width}%"
  end

  def render(assigns) do
    ~F"""
    <div class="rounded-lg shadow-2xl p-6 h-full">
      <div class="flex flex-col">
        <div class="flex flex-row gap-4">
          <div :for={bar <- bars(@scale, @values)} style={"width: #{bar_width(@scale, @values)}"}>
            <div class="flex flex-col items-center gap-2 w-full">
              <div class="flex flex-col items-center w-full">
                <div style={"height: #{bar_top_height(bar)}px"}></div>
                <div class="pb-1 text-caption font-caption text-grey1">{bar.value_count}</div>
                <div :if={bar_height(bar) > 0} style={"height: #{bar_height(bar)}px"} class="flex-grow bg-primary w-full rounded-t-lg"></div>
                <div :if={bar_height(bar) <= 0} class="bg-grey4 w-full h-2px"></div>
              </div>
              <div class="text-caption font-caption text-grey2">{bar.range}</div>
            </div>
          </div>
        </div>
        <div class="flex flex-row mt-6 items-center">
          <div class="text-title7 font-title7 text-left text-grey1"><span class="text-primary">↑</span> Students</div>
          <div class="flex-grow" />
          <div class="text-title7 font-title7 text-right text-grey1">Credits <span class="text-primary">→</span></div>
        </div>
      </div>
    </div>
    """
  end
end

defmodule Framworks.Pixel.Widget.ValueDistribution.Example do
  use Surface.Catalogue.Example,
    subject: Frameworks.Pixel.Widget.ValueDistribution,
    catalogue: Frameworks.Pixel.Catalogue,
    height: "412px",
    container: {:div, class: ""},
    direction: "vertical"

  def render(assigns) do
    ~F"""
      <div class="flex flex-col gap-8">
        <ValueDistribution scale={10} values={[0,0,1,1,2,3,4,5,6,7,8,9,10,16,17,18,20,22,34,37,40,41,42,44,50,51,52,53,54,55,56,57,58,59,59,59,59,60]} />
      </div>
    """
  end
end
