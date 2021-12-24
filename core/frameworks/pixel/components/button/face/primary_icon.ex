defmodule Frameworks.Pixel.Button.Face.PrimaryIcon do
  @moduledoc """
  A colored button with white text and an icon to the left
  """
  use Frameworks.Pixel.Component

  prop(vm, :map, required: true)

  defviewmodel(
    label: nil,
    icon: nil,
    bg_color: "bg-primary",
    text_color: "text-white"
  )

  def render(assigns) do
    ~F"""
    <div class={"pt-1 pb-1 active:pt-5px active:pb-3px active:shadow-top4px w-full rounded pl-4 pr-4 #{bg_color(@vm)}"}>
      <div class="flex justify-center items-center w-full">
        <div>
            <img class="mr-3 -mt-1" src={"/images/icons/#{icon(@vm)}.svg"} alt={label(@vm)}/>
        </div>
        <div class="h-10">
          <div class="flex flex-col justify-center h-full items-center">
            <div class={"text-button font-button #{text_color(@vm)}"}>
              {label(@vm)}
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
