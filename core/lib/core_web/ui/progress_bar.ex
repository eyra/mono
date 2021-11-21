defmodule CoreWeb.UI.ProgressBar do
  @moduledoc """
    Progress bar capable of stacking multiple bars.
    The bars will be sorted on size and will be stacked from large to small.
  """
  use Surface.Component

  prop(size, :integer, default: 0)
  prop(bars, :list, default: [])
  prop(bg_color, :string, default: "bg-grey4")

  defp hide(0, _), do: true

  defp hide(total_size, %{size: size}) do
    size / total_size == 1
  end

  defp width(0, _), do: 0

  defp width(total_size, %{size: size}) do
    size / total_size * 100
  end

  defp min_width(0, _bars, _bar, _index), do: "0px"
  defp min_width(_size, _bars, %{size: 0}, _index), do: "0px"
  defp min_width(_size, bars, _bar, index), do: "#{24 + 12 * (Enum.count(bars) - (index + 1))}px"

  defp color(%{color: color}), do: "bg-#{color}"

  defp sort_by_size(bars) do
    bars |> Enum.sort_by(& &1.size, :desc)
  end

  def render(assigns) do
    ~H"""
    <div class="relative h-6 mb-12">
      <div class="absolute w-full h-6 rounded-full {{ @bg_color }}">
      </div>
      <div :for={{ {bar, index} <- Enum.with_index(sort_by_size(@bars)) }} class="absolute h-6 w-full">
        <div style="min-width: {{min_width(@size, @bars, bar, index)}}; width: {{width(@size, bar)}}%" class="absolute h-6 rounded-full bg-white ml-2px {{ hide(@size, bar) }}"></div>
        <div style="min-width: {{min_width(@size, @bars, bar, index)}}; width: {{width(@size, bar)}}%" class="absolute h-6 rounded-full {{color(bar)}}"></div>
      </div>
    </div>
    """
  end
end

defmodule CoreWeb.UI.ProgressBar.Example do
  use Surface.Catalogue.Example,
    subject: CoreWeb.UI.ProgressBar,
    catalogue: Frameworks.Pixel.Catalogue,
    height: "420px",
    container: {:div, class: ""}

  def render(assigns) do
    ~H"""
    <ProgressBar :props={{ %{size: 0, bars: [%{ color: :primary, size: 100}]} }} />
    <ProgressBar :props={{ %{size: 100, bars: [%{ color: :primary, size: 100}]} }} />
    <ProgressBar :props={{ %{size: 100, bars: [%{ color: :primary, size: 100}, %{ color: :secondary, size: 50}]} }} />
    <ProgressBar :props={{ %{size: 100, bars: [%{ color: :primary, size: 100}, %{ color: :secondary, size: 50}, %{ color: :tertiary, size: 1}]} }} />
    <ProgressBar :props={{ %{size: 100, bars: [%{ color: :primary, size: 100}, %{ color: :secondary, size: 50}, %{ color: :tertiary, size: 1}, %{ color: :grey1, size: 1}]} }} />
    """
  end
end

defmodule CoreWeb.UI.ProgressBar.Playground do
  use Surface.Catalogue.Playground,
    subject: CoreWeb.UI.ProgressBar,
    catalogue: Frameworks.Pixel.Catalogue,
    height: "110px",
    container: {:div, class: "buttons is-centered"}

  data(props, :map,
    default: %{
      size: 100,
      bars: [
        %{color: :primary, size: 100},
        %{color: :secondary, size: 50}
      ]
    }
  )

  def render(assigns) do
    ~H"""
    <ProgressBar :props={{ @props }} />
    """
  end
end
