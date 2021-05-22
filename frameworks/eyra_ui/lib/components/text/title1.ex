defmodule EyraUI.Text.Title1 do
  @moduledoc """
  This title is to be used for ...?
  """
  use Surface.Component

  slot(default, required: true)
  prop(color, :css_class, default: "text-grey1")

  def render(assigns) do
    ~H"""
    <div class="text-title3 font-title3 sm:text-title2 lg:text-title1 lg:font-title1 mb-7 lg:mb-9">
      <slot />
    </div>
    """
  end
end
