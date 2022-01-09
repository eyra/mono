defmodule Frameworks.Pixel.Text.BodyMedium do
  @moduledoc """
  The body medium is to be used for ...?
  """
  use Surface.Component

  slot(default, required: true)
  prop(color, :css_class, default: "text-grey1")
  prop(align, :css_class, default: "text-left")

  def render(assigns) do
    ~F"""
    <div class={"flex-wrap text-bodymedium font-body #{@color} #{@align}"}>
      <#slot />
    </div>
    """
  end
end
