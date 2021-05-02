defmodule EyraUI.Text.Title2 do
  @moduledoc """
  This title is to be used for ...?
  """
  use Surface.Component

  slot(default, required: true)
  prop(color, :css_class, default: "text-grey1")

  def render(assigns) do
    ~H"""
    <div class="text-title5 font-title5 sm:text-title3 sm:font-title3 lg:text-title2 lg:font-title2 mb-7 lg:mb-9 {{@color}}">
      <slot />
    </div>
    """
  end
end
