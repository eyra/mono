defmodule EyraUI.Button.DeleteButton do
  @moduledoc """
  A colored button with white text
  """
  use Surface.Component

  prop(path, :string, required: true)
  prop(label, :string, required: true)

  def render(assigns) do
    ~H"""
    <a href= {{ @path }} data-to={{ @path }} data-csrf={{ Plug.CSRFProtection.get_csrf_token_for(@path) }} data-method="delete" >
      <div class="flex">
        <div class="flex-wrap h-11 ring-2 ring-delete focus:outline-none hover:opacity-80 rounded bg-white mr-4">
          <div class="flex flex-col justify-center h-full items-center rounded">
            <div class="text-delete text-button font-button pl-4 pr-4">
              {{ @label }}
            </div>
          </div>
        </div>
      </div>
    </a>
    """
  end
end
