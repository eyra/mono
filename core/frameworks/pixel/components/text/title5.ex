defmodule Frameworks.Pixel.Text.Title5 do
  @moduledoc """
  This title is to be used for ...?
  """

  use Surface.Component

  slot(default, required: true)
  prop(color, :css_class, default: "text-grey1")

  def render(assigns) do
    ~F"""
    <div class={"text-title7 font-title7 sm:text-title5 sm:font-title5 text-center #{@color}"}>
      <#slot />
    </div>
    """
  end
end
