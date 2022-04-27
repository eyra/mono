defmodule Frameworks.Pixel.Selector.Radio do
  @moduledoc false
  use Frameworks.Pixel.Component

  prop(item, :map, required: true)
  prop(multiselect?, :boolean, default: true)
  prop(background, :atom, default: :light)

  defp label_color(%{background: :dark}), do: "text-white"
  defp label_color(_), do: "text-grey1"

  defp active_icon(%{background: :dark}), do: "radio_active_tertiary"
  defp active_icon(_), do: "radio_active"

  defp inactive_icon(_), do: "radio"

  def render(assigns) do
    ~F"""
    <div class="flex flex-row gap-3 items-center">
      <div>
        <img x-show="active" src={"/images/icons/#{active_icon(assigns)}.svg"} alt={"#{@item.value} is selected"} />
        <img x-show="!active" src={"/images/icons/#{inactive_icon(assigns)}.svg"} alt={"Select #{@item.value}"} />
      </div>
      <div class={"#{label_color(assigns)} text-label font-label select-none mt-1"}>
        {@item.value}
      </div>
    </div>
    """
  end
end
