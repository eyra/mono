defmodule EyraUI.Text.Title0 do
  @moduledoc """
  This title is to be used for ...?
  """
  use Surface.Component

  slot(default, required: true)
  prop(color, :css_class, default: "text-grey1")

  def render(assigns) do
    ~H"""
    <div class="text-title4 font-title4 sm:text-title2 sm:font-title2 lg:text-title0 lg:font-title0 {{@color}}">
      <slot />
    </div>
    """
  end
end
