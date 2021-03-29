defmodule EyraUI.Button.SubmitButton do
  @moduledoc """
  A colored button with white text
  """
  use Surface.Component

  prop(label, :string, required: true)
  prop(bg_color, :css_class, default: "bg-primary")
  prop(alpine_onclick, :string)

  def render(assigns) do
    ~H"""
    <button x-on:click={{@alpine_onclick}} class="h-48px leading-none font-button text-button text-white focus:outline-none active:opacity-80 rounded pr-4 pl-4 {{@bg_color}}" type="submit">
      {{ @label }}
    </button>
    """
  end
end
