defmodule Frameworks.Pixel.Text.Title2 do
  @moduledoc """
  This title is to be used for ...?
  """
  use Surface.Component

  slot(default, required: true)
  prop(color, :string, default: "text-grey1")
  prop(margin, :string, default: "mb-6 md:mb-8 lg:mb-10")

  def render(assigns) do
    ~F"""
    <div class={"text-title4 font-title4 sm:text-title3 sm:font-title3 lg:text-title2 lg:font-title2 #{@margin} #{@color}"}>
      <#slot />
    </div>
    """
  end
end
