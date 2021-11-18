defmodule Frameworks.Pixel.Tag do
  @moduledoc """
  A colored button with white text
  """
  use Surface.Component

  prop(text, :string, required: true)
  prop(bg_color, :string, default: "bg-primary")
  prop(text_color, :css_class, default: "text-primary")
  prop(bg_opacity, :css_class, default: "bg-opacity-20")

  def render(assigns) do
    ~H"""
    <div class="h-8 bg-white rounded">
      <div class="flex flex-col justify-center h-full rounded items-center {{@bg_color}} {{@bg_opacity}}">
        <div class="text-label font-label ml-3 mr-3 {{@text_color}}">
          {{ @text }}
        </div>
      </div>
    </div>
    """
  end
end
