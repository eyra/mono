defmodule Frameworks.Pixel.Card.Card do
  @moduledoc """
  The Unique Selling Point Card highlights a reason for taking an action.
  """
  use Surface.LiveComponent

  @doc "The card image"
  slot(image)

  @doc "The card title"
  slot(title)

  @doc "The card content, can be button, description etc."
  slot(default, required: true)

  prop(bg_color, :css_class, default: "bg-grey6")
  prop(size, :css_class, default: "h-full")
  prop(click_event_data, :string)

  def render(assigns) do
    ~F"""
    <div class={"relative rounded-lg cursor-pointer #{@bg_color} #{@size}"}>
      <#slot {@image} />
      <div class="p-6 lg:pl-8 lg:pr-8 lg:pt-10 lg:pb-10">
        <#slot {@title} />
        <#slot />
      </div>
    </div>
    """
  end
end
