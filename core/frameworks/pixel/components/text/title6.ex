defmodule Frameworks.Pixel.Text.Title6 do
  @moduledoc """
  This title is to be used for ...?
  """

  use Surface.Component

  slot(default, required: true)
  prop(color, :css_class, default: "text-grey1")

  def render(assigns) do
    ~H"""
    <div class="text-title6 font-title6 mb-2 {{@color}}">
      <slot />
    </div>
    """
  end
end
