defmodule EyraUI.Text.BodyMedium do
  @moduledoc """
  The body medium is to be used for ...?
  """
  use Surface.Component

  slot(default, required: true)
  prop(color, :css_class, default: "text-grey1")

  def render(assigns) do
    ~H"""
    <div class="flex-wrap text-bodymedium font-body {{@color}}">
      <slot />
    </div>
    """
  end
end
