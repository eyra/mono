defmodule Frameworks.Pixel.Icon do
  use Surface.Component

  prop(type, :atom, required: true)
  prop(src, :any, required: true)
  prop(size, :string)
  prop(border_size, :css_class, default: "border-0")
  prop(border_radius, :css_class, default: "rounded-none")
  prop(bg_color, :css_class, default: false)

  defp size("L"), do: "w-12 h-12 sm:h-16 sm:w-16 lg:h-84px lg:w-84px"
  defp size("S"), do: "h-14 w-14"
  defp size(_), do: ""

  defp emoji_style("L"), do: "text-title1 font-title1 text-grey1"
  defp emoji_style("M"), do: "text-title2 font-title2 text-grey1"
  defp emoji_style("S"), do: "text-title3 font-title3 text-grey1"

  def render(assigns) do
    ~F"""
    <div class={"border-grey4 border-opacity-100 #{size(@size)} #{@bg_color} #{@border_size} #{@border_radius}"}>
      <img :if={@type == :url} class={"w-full h-full #{@border_radius}"} src={@src} alt="">
      <img :if={@type == :static} src={"/images/icons/#{@src}.svg"} alt="">
      <div :if={@type == :emoji} class={"w-full h-full #{@border_radius} #{emoji_style("M")}"}>{@src}</div>
    </div>
    """
  end
end
