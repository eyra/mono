defmodule Frameworks.Pixel.Widget.Metric do
  use Frameworks.Pixel.Component

  alias Frameworks.Pixel.Text.Label

  prop(number, :integer, required: true)
  prop(label, :string, required: true)
  prop(color, :atom, default: :primary)
  prop(target, :any, default: nil)
  prop(target_direction, :atom, default: nil)

  defp number_color(number, target, :up, _) when number < target, do: "text-warning"
  defp number_color(number, target, :up, _) when number >= target, do: "text-success"

  defp number_color(number, target, :down, _) when number > target, do: "text-delete"
  defp number_color(number, target, :down, _) when number <= target, do: "text-success"

  defp number_color(_, _, _, :positive), do: "text-success"
  defp number_color(_, _, _, :negative), do: "text-delete"
  defp number_color(_, _, _, :warning), do: "text-warning"
  defp number_color(_, _, _, _), do: "text-primary"

  def render(assigns) do
    ~F"""
    <div class="h-full">
      <div class="flex flex-col gap-2 rounded-lg shadow-2xl p-6 h-full">
        <div class={"font-title0 text-title0 #{number_color(@number, @target, @target_direction, @color)}"}>{@number}</div>
        <Label>{@label}</Label>
      </div>
    </div>
    """
  end
end

defmodule Framworks.Pixel.Widget.Metric.Example do
  use Surface.Catalogue.Example,
    subject: Frameworks.Pixel.Widget.Metric,
    catalogue: Frameworks.Pixel.Catalogue,
    height: "1024px",
    container: {:div, class: ""}

  def render(assigns) do
    ~F"""
      <div class="flex flex-col gap-8 h-full">
        <Metric number={7} label={"Pool size"} />
        <Metric number={7} label={"Pool size"} color={:positive}/>
        <Metric number={7} label={"Pool size"} color={:negative}/>
      </div>
    """
  end
end
