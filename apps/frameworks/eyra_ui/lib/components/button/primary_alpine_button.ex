defmodule EyraUI.Button.PrimaryAlpineButton do
  @moduledoc """
  A colored button with white text
  """
  use Surface.Component

  prop(label, :string, required: true)
  prop(click, :string, required: true)
  prop(bg_color, :css_class, default: "bg-primary")
  prop(text_color, :css_class, default: "text-white")

  def render(assigns) do
    ~H"""
    <button @click={{@click}} class="h-48px leading-none font-button text-button focus:outline-none active:opacity-80 rounded pr-4 pl-4 {{@bg_color}} {{@text_color}}" type="button">
      {{ @label }}
    </button>
    """
  end
end
