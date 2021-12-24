defmodule Frameworks.Pixel.Text.SubHead do
  @moduledoc """
  This subhead is to be used for ...?
  """

  use Surface.Component

  slot(default, required: true)
  prop(color, :css_class, default: "text-grey2")

  def render(assigns) do
    ~F"""
    <div class={"text-intro lg:text-subhead font-subhead tracking-wider #{@color}"}>
      <#slot />
    </div>
    """
  end
end
