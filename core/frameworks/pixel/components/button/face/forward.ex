defmodule Frameworks.Pixel.Button.Face.Forward do
  @moduledoc """
    A text button with a forward arrow on the right
  """
  use Frameworks.Pixel.Component

  prop(vm, :map, required: true)

  defviewmodel(
    label: nil,
    icon: "/images/forward.svg",
    text_color: "text-grey1"
  )

  def render(assigns) do
    ~H"""
    <div class="pt-1 pb-1 active:pt-5px active:pb-3px rounded bg-opacity-0 focus:outline-none">
      <div class="flex items-center">
        <div class="focus:outline-none">
          <div class="flex flex-col justify-center h-full items-center">
            <div class="flex-wrap text-button font-button {{text_color(@vm)}}">
              {{ label(@vm) }}
            </div>
          </div>
        </div>
        <div>
            <img class="ml-4 -mt-2px" src={{icon(@vm)}} alt={{label(@vm)}} />
        </div>
      </div>
    </div>
    """
  end
end
