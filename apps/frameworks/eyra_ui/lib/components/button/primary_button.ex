defmodule EyraUI.Button.PrimaryButton do
  @moduledoc """
  A colored button with white text
  """
  use Surface.Component

  prop(path, :string, required: true)
  prop(label, :string, required: true)
  prop(bg_color, :css_class, default: "bg-primary")

  def render(assigns) do
    ~H"""
    <a href= {{ @path }} >
      <div class="flex">
        <div class="flex-wrap h-11 focus:outline-none hover:opacity-80 rounded mr-4 {{@bg_color}}">
          <div class="flex flex-col justify-center h-full items-center rounded">
            <div class="text-white text-button font-button pl-4 pr-4">
              {{ @label }}
            </div>
          </div>
        </div>
      </div>
    </a>
    """
  end
end
