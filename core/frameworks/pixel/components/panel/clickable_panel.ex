defmodule Frameworks.Pixel.Panel.ClickablePanel do
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
  prop(padding, :string, default: "p-6 lg:p-8")

  prop(event, :string, default: "handle_panel_click")
  prop(item, :string, required: true)

  def render(assigns) do
    ~F"""
    <div
      phx-click={@event}
      phx-value-item={@item}
      class={@bg_color, @size, "rounded-md", "cursor-pointer"}
    >
      <div class={"#{@padding} #{@align}"}>
        <#slot name="title" />
        <#slot />
      </div>
    </div>
    """
  end
end
