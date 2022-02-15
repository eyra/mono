defmodule Frameworks.Pixel.Button.Face.Icon do
  @moduledoc """
  A colored button with white text and an icon to the left
  """
  use Frameworks.Pixel.Component
  use PhoenixInlineSvg.Helpers
  use Phoenix.HTML

  prop(vm, :map, required: true)

  defviewmodel(
    icon: nil,
    color: nil,
    alt: ""
  )

  def icon_name(%{icon: icon, color: nil}), do: "#{icon}"
  def icon_name(%{icon: icon, color: color}), do: "#{icon}_#{color}"
  def icon_name(%{icon: icon}), do: "#{icon}"

  def render(assigns) do
    ~F"""
    <div class="active:opacity-80 cursor-pointer h-6 w-6">
      <img src={"/images/icons/#{icon_name(@vm)}.svg"} alt={alt(@vm)}/>
    </div>
    """
  end
end
