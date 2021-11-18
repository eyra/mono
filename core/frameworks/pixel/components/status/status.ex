defmodule Frameworks.Pixel.Status.Status do
  @moduledoc """
  A colored button with white text
  """
  use Surface.Component

  prop(text, :string, required: true)
  prop(bg_color, :string, required: true)
  prop(text_color, :string, required: true)
  prop(bg_opacity, :string, required: true)

  def render(assigns) do
    ~H"""
    <div class="flex h-10">
      <div>
        <div class="flex flex-col justify-center h-full items-center rounded {{@bg_color}} {{@bg_opacity}}">
          <div class="text-label font-label ml-4 mr-4 {{@text_color}}">
            {{ @text }}
          </div>
        </div>
      </div>
    </div>
    """
  end
end
