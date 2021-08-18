defmodule EyraUI.Text.Title1 do
  @moduledoc """
  This title is to be used for ...?
  """
  use Surface.Component

  slot(default, required: true)
  prop(color, :css_class, default: "text-grey1")
  prop(margin, :css_class, default: "mb-7 lg:mb-9")

  def render(assigns) do
    ~H"""
    <div class="text-title3 font-title3 sm:text-title2 lg:text-title1 lg:font-title1 {{ @margin }}">
      <slot />
    </div>
    """
  end
end
