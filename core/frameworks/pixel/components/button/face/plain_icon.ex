defmodule Frameworks.Pixel.Button.Face.PlainIcon do
  @moduledoc """
    A plain text button with an icon on the right
  """
  use Frameworks.Pixel.Component

  prop(vm, :map, required: true)

  defviewmodel(
    label: nil,
    icon: :forward,
    text_color: "text-grey1"
  )

  def render(assigns) do
    ~F"""
    <div class="pt-1 pb-1 active:pt-5px active:pb-3px rounded bg-opacity-0 focus:outline-none">
      <div class="flex items-center">
        <div class="focus:outline-none">
          <div class="flex flex-col justify-center h-full items-center">
            <div class={"flex-wrap text-button font-button #{text_color(@vm)}"}>
              {label(@vm)}
            </div>
          </div>
        </div>
        <div>
          <img class="ml-4 -mt-2px" src={"/images/icons/#{icon(@vm)}.svg"} alt={label(@vm)} />
        </div>
      </div>
    </div>
    """
  end
end
