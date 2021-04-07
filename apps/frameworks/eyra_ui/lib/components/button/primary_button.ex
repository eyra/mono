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
        <div class="flex-wrap pt-15px pb-15px active:shadow-top4px active:pt-4 active:pb-14px focus:outline-none rounded mr-4 {{@bg_color}}">
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
