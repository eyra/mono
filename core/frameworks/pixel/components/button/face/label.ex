defmodule Frameworks.Pixel.Button.Face.Label do
  @moduledoc """
  A colored button with white text
  """
  use Frameworks.Pixel.Component

  prop(vm, :map, required: true)

  defviewmodel(
    label: nil,
    wrap: false,
    text_color: "text-primary",
    font: "font-button text-button"
  )

  def padding(%{wrap: true}), do: "pt-1px pb-1px active:pt-2px active:pb-0"
  def padding(_), do: "pt-13px pb-13px active:pt-14px active:pb-3 pr-4 pl-4"

  def render(assigns) do
    ~F"""
    <div class={"rounded bg-opacity-0 #{font(@vm)} #{padding(@vm)} #{text_color(@vm)}"}>
      {label(@vm)}
    </div>
    """
  end
end
