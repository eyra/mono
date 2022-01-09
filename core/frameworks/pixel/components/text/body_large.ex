defmodule Frameworks.Pixel.Text.BodyLarge do
  @moduledoc """
  The body large is to be used for ...?
  """
  use Surface.Component

  slot(default, required: true)
  prop(color, :css_class, default: "text-grey1")
  prop(align, :css_class, default: "text-left")

  def render(assigns) do
    ~F"""
    <div class={"flex-wrap text-bodylarge font-body #{@color} #{@align}"}>
      <#slot />
    </div>
    """
  end
end
