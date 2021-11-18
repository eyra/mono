defmodule Frameworks.Pixel.Text.Label do
  @moduledoc """
  This label is to be used for ...?
  """
  use Surface.Component

  slot(default, required: true)
  prop(color, :css_class, default: "text-grey1")

  def render(assigns) do
    ~H"""
    <div class="text-label font-label leading-5 {{@color}}">
      <slot />
    </div>
    """
  end
end
