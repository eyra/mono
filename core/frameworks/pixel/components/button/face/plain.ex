defmodule Frameworks.Pixel.Button.Face.Plain do
  @moduledoc """
    A plain text button
  """
  use Frameworks.Pixel.Component

  prop(vm, :map, required: true)

  defviewmodel(
    label: nil,
    text_color: "text-grey1"
  )

  def render(assigns) do
    ~F"""
    <div class="pt-1 pb-1 active:pt-5px active:pb-3px rounded bg-opacity-0 focus:outline-none">
      <div class="flex items-center">
        <div class="focus:outline-none">
          <div class="flex flex-col justify-center h-full items-center">
            <div class={"flex-wrap text-button font-button #{text_color(@vm)}"}>
              <span class="whitespace-pre-wrap">{label(@vm)}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
