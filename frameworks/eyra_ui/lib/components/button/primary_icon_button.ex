defmodule EyraUI.Button.PrimaryIconButton do
  @moduledoc """
  A colored button with white text
  """
  use Surface.Component
  alias Surface.Components.LiveRedirect

  prop(to, :string, required: true)
  prop(label, :string, required: true)
  prop(icon, :string, required: true)
  prop(bg_color, :string, required: true)

  def render(assigns) do
    ~H"""
    <LiveRedirect to={{ @to }} >
      <div class="pt-1 pb-1 active:pt-5px active:pb-3px active:shadow-top4px w-full rounded pl-4 pr-4 {{@bg_color}}">
        <div class="flex justify-center items-center w-full">
          <div>
              <img class="mr-3 -mt-1" src={{@icon}}/>
          </div>
          <div class="h-10 focus:outline-none">
            <div class="flex flex-col justify-center h-full items-center">
              <div class="text-white text-button font-button">
                {{ @label }}
              </div>
            </div>
          </div>
        </div>
      </div>
    </LiveRedirect>
    """
  end
end
