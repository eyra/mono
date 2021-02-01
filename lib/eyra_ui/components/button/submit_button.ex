defmodule EyraUI.Button.SubmitButton do
  @moduledoc """
  A colored button with white text
  """
  use Surface.Component

  prop label, :string, required: true
  prop color, :css_class, default: "bg-primary"
  prop width, :css_class, default: "p-4"

  def render(assigns) do
    ~H"""
    <button class="h-48px leading-none font-button text-button text-white focus:outline-none hover:bg-opacity-80 rounded {{ @color }} {{ @width }}" type="submit">
      {{ @label }}
    </button>
    """
  end
end
