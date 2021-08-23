defmodule EyraUI.Button.Face.Secondary do
  @moduledoc """
  A colored button with white text
  """
  use EyraUI.Component

  prop(vm, :map, required: true)

  defviewmodel(
    label: nil,
    border_color: "bg-primary",
    text_color: "text-primary"
  )

  def render(assigns) do
    ~H"""
    <div class="pt-13px pb-13px active:pt-14px active:pb-3 active:shadow-top2px border-2 font-button text-button focus:outline-none rounded bg-opacity-0 pr-4 pl-4 {{border_color(@vm)}} {{text_color(@vm)}}">
      {{ label(@vm) }}
    </div>
    """
  end
end
