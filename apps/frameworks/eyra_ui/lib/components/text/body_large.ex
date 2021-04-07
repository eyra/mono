defmodule EyraUI.Text.BodyLarge do
  @moduledoc """
  The body large is to be used for ...?
  """
  use Surface.Component

  slot(default, required: true)
  prop(color, :css_class, default: "text-grey1")

  def render(assigns) do
    ~H"""
    <div class="flex-wrap text-bodylarge font-body {{@color}}">
      <slot />
    </div>
    """
  end
end
