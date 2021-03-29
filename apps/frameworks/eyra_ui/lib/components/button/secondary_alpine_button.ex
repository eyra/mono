defmodule EyraUI.Button.SecondaryAlpineButton do
  @moduledoc """
  A colored button with white text
  """
  use Surface.Component

  prop(label, :string, required: true)
  prop(click, :string, required: true)
  prop(ring_color, :css_class, default: "ring-primary")
  prop(text_color, :css_class, default: "text-primary")

  def render(assigns) do
    ~H"""
    <button @click={{@click}} class="h-11 ring-2 leading-none font-button text-button focus:outline-none active:opacity-80 rounded pr-4 pl-4 {{@ring_color}} {{@text_color}}" type="button">
      {{ @label }}
    </button>
    """
  end
end
