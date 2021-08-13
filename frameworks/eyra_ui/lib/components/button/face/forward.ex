defmodule EyraUI.Button.Face.Forward do
  @moduledoc """
    A text button with a forward arrow on the right
  """
  use Surface.Component

  prop(label, :string, required: true)
  prop(icon, :string, default: "/images/forward.svg")
  prop(text_color, :css_class, default: "text-grey1")

  def render(assigns) do
    ~H"""
    <div class="pt-1 pb-1 active:pt-5px active:pb-3px rounded bg-opacity-0 focus:outline-none">
      <div class="flex items-center">
        <div class="focus:outline-none">
          <div class="flex flex-col justify-center h-full items-center">
            <div class="flex-wrap text-button font-button {{@text_color}}">
              {{ @label }}
            </div>
          </div>
        </div>
        <div>
            <img class="ml-4 -mt-2px" src={{@icon}}/>
        </div>
      </div>
    </div>
    """
  end
end
