defmodule EyraUI.Button.PrimaryWideButton do
  @moduledoc """
  A colored button with white text
  """
  use Surface.Component

  prop path, :string, required: true
  prop label, :string, required: true
  prop bg_color, :string, required: true

  def render(assigns) do
    ~H"""
    <a href= {{ @path }} >
      <div class="flex w-full {{@bg_color}} rounded justify-center items-center pl-4 pr-4">
        <div class="h-11 focus:outline-none hover:opacity-80">
          <div class="flex flex-col justify-center h-full items-center rounded">
            <div class="text-white text-button font-button">
              {{ @label }}
            </div>
          </div>
        </div>
      </div>
    </a>
    """
  end
end
