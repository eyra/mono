defmodule Frameworks.Pixel.Text.Title6 do
  @moduledoc """
  This title is to be used for ...?
  """

  use Surface.Component

  slot(default, required: true)
  prop(color, :css_class, default: "text-grey1")
  prop(margin, :string, default: "mb-2")

  def render(assigns) do
    ~F"""
    <div class={"text-title6 font-title6 #{@margin} #{@color}"}>
      <#slot />
    </div>
    """
  end
end
