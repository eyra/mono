defmodule EyraUI.Button.Face.LabelIcon do
  @moduledoc """
  A colored button with white text and an icon to the left
  """
  use EyraUI.Component

  prop(vm, :map, required: true)

  defviewmodel(
    label: nil,
    icon: nil,
    text_color: "text-grey1"
  )

  def render(assigns) do
    ~H"""
    <div class="pt-0 pb-1px active:pt-1px active:pb-0 font-button text-button rounded bg-opacity-0">
      <div class="flex justify-left items-center w-full">
        <div>
            <img class="mr-3 -mt-2px" src="/images/icons/{{icon(@vm)}}.svg"/>
        </div>
        <div class="h-10">
          <div class="flex flex-col justify-center h-full items-center">
            <div class="text-label font-label {{text_color(@vm)}}">
              {{ label(@vm) }}
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
