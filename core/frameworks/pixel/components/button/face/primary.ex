defmodule Frameworks.Pixel.Button.Face.Primary do
  @moduledoc """
  A colored button with white text
  """
  use Frameworks.Pixel.Component

  prop(vm, :map, required: true)

  defviewmodel(
    label: nil,
    icon: nil,
    bg_color: "bg-primary",
    text_color: "text-white"
  )

  def render(assigns) do
    ~F"""
    <div class={"pt-15px pb-15px active:shadow-top4px active:pt-4 active:pb-14px leading-none font-button text-button rounded pr-4 pl-4 #{bg_color(@vm)} #{text_color(@vm)}"}>
      {label(@vm)}
    </div>
    """
  end
end
