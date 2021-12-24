defmodule Frameworks.Pixel.Text.Intro do
  @moduledoc """
  The intro is to be used for ...?
  """
  use Surface.Component

  slot(default, required: true)
  prop(color, :css_class, default: "text-grey1")

  def render(assigns) do
    ~F"""
    <div class={"text-intro lg:text-introdesktop font-intro lg:mb-9 #{@color}"}>
      <#slot />
    </div>
    """
  end
end
