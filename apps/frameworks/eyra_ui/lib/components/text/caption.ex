defmodule EyraUI.Text.Caption do
  @moduledoc """
  This title is to be used for ...?
  """

  use Surface.Component

  slot(default, required: true)
  prop(color, :css_class, default: "text-grey3")
  prop(text_alignment, :css_class, default: "text-center")
  prop(padding, :css_class, default: "pl-4 pr-4")
  prop(margin, :css_class, default: "mb-6")

  def render(assigns) do
    ~H"""
    <div class="text-caption {{@padding}} {{@text_alignment}} {{@color}}">
      <slot />
    </div>
    """
  end
end
