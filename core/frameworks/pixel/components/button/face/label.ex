defmodule Frameworks.Pixel.Button.Face.Label do
  @moduledoc """
  A colored button with white text
  """
  use Frameworks.Pixel.Component

  prop(vm, :map, required: true)

  defviewmodel(
    label: nil,
    text_color: "text-primary"
  )

  def render(assigns) do
    ~H"""
    <div class="pt-13px pb-13px active:pt-14px active:pb-3 font-button text-button rounded bg-opacity-0 pr-4 pl-4 {{text_color(@vm)}}">
      {{ label(@vm) }}
    </div>
    """
  end
end
