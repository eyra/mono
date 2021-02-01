defmodule EyraUI.Button.PrimaryButton do
  @moduledoc """
  A colored button with white text
  """
  use Surface.Component

  prop path, :string, required: true
  prop label, :string, required: true
  prop color, :css_class, default: "bg-primary"
  prop width, :css_class, default: "w-full"

  def render(assigns) do
    ~H"""
    <a href= {{ @path }}>
    <div class="flex items-center justify-center leading-none pl-4 pr-4 h-48px focus:outline-none hover:bg-opacity-80 rounded {{ @color }} {{ @width }}">
        <div class="text-white text-button font-button">{{ @label }}</div>
    </div>
    </a>
    """
  end
end
