defmodule EyraUI.Text.Bullet do
  @moduledoc """
  This title is to be used for ...?
  """
  use Surface.Component

  slot(default, required: true)
  prop(color, :css_class, default: "text-grey1")
  prop(image, :string, required: true)

  def render(assigns) do
    ~H"""
    <div class="flex items-center">
      <div class="flex-wrap h-3 w-3 mr-3 flex-shrink-0 {{@color}}">
        <img src={{@image}} alt="" />
      </div>
      <slot />
    </div>
    """
  end
end
