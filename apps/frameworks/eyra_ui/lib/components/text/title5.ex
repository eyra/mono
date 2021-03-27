defmodule EyraUI.Text.Title5 do
  @moduledoc """
  This title is to be used for ...?
  """

  use Surface.Component

  slot(default, required: true)
  prop(color, :css_class, default: "text-grey1")

  def render(assigns) do
    ~H"""
    <div class="text-title5 font-title5 {{@color}}">
      <slot />
    </div>
    """
  end
end
