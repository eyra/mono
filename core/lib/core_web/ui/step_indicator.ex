defmodule CoreWeb.UI.StepIndicator do
  @moduledoc """
    Circle with a number
  """
  use Frameworks.Pixel.Component

  defviewmodel(
    text: nil,
    bg_color: "bg-primary",
    text_color: "text-white"
  )

  prop(vm, :any, required: true)

  def center_correction_for_number(1), do: "mr-1px"
  def center_correction_for_number(4), do: "mr-1px"
  def center_correction_for_number(_), do: ""

  def render(assigns) do
    ~F"""
    <div class={"w-6 h-6 font-caption text-caption rounded-full flex items-center #{bg_color(@vm)} #{text_color(@vm)}"}>
      <span class={"text-center w-full mt-1px #{center_correction_for_number(text(@vm))}"}>{text(@vm)}</span>
    </div>
    """
  end
end
