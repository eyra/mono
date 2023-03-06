defmodule Frameworks.Pixel.Text.Title5 do
  @moduledoc """
  This title is to be used for ...?
  """

  use Surface.Component

  slot(default, required: true)
  prop(color, :css_class, default: "text-grey1")
  prop(align, :css_class, default: "text-center")

  def render(assigns) do
    ~F"""
    <div class={"text-title7 font-title7 sm:text-title5 sm:font-title5 #{@align} #{@color}"}>
      <#slot />
    </div>
    """
  end
end
