defmodule EyraUI.Button.Face.Secondary do
  @moduledoc """
  A colored button with white text
  """
  use Surface.Component

  prop(label, :string, required: true)
  prop(border_color, :css_class, default: "border-primary")
  prop(text_color, :css_class, default: "text-primary")

  def render(assigns) do
    ~H"""
    <div class="pt-13px pb-13px active:pt-14px active:pb-3 active:shadow-top2px border-2 leading-none font-button text-button focus:outline-none rounded pr-4 pl-4 {{@border_color}} {{@text_color}}">
      {{ @label }}
    </div>
    """
  end
end
