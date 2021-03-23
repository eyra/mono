defmodule EyraUI.Text.SubHead do
  @moduledoc """
  This subhead is to be used for ...?
  """

  use Surface.Component

  slot(default, required: true)
  prop(color, :css_class, default: "text-grey2")

  def render(assigns) do
    ~H"""
    <div class="text-intro lg:text-subhead font-subhead mb-4 lg:mb-9 tracking-wider {{@color}}">
      <slot />
    </div>
    """
  end
end
