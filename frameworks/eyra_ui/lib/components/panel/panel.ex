defmodule EyraUI.Panel.Panel do
  @moduledoc """
    Grouping information in a card-like fashion.
  """
  use Surface.Component

  @doc "The panel title"
  slot(title)

  @doc "The panel content, can be button, description etc."
  slot(default, required: true)

  prop(bg_color, :css_class, default: "bg-grey6")
  prop(size, :css_class, default: "h-full")
  prop(align, :css_class, default: "text-left")

  def render(assigns) do
    ~H"""
    <div class={{ @bg_color, @size, "rounded-md" }}>
      <div class="p-6 lg:pl-8 lg:pr-8 lg:pt-10 lg:pb-10 {{@align}}">
        <slot name="title" />
        <slot />
      </div>
    </div>
    """
  end
end
