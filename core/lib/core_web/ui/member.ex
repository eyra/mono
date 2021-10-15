defmodule CoreWeb.UI.Member do
  @moduledoc """
    Label with a pill formed background.
  """
  use CoreWeb.UI.Component

  alias Core.ImageHelpers

  alias EyraUI.Button.DynamicButton
  alias EyraUI.Text.{Title3, SubHead}
  alias EyraUI.Wrap

  defviewmodel(
    title: nil,
    subtitle: nil,
    photo_url: nil,
    button_large: nil,
    button_small: nil,
    gender: nil
  )

  prop(vm, :map, required: true)

  def render(assigns) do
    ~H"""
    <div class="bg-grey1 rounded-md p-6 sm:p-8">
      <div class="flex flex-row gap-4 md:gap-8 h-full">
        <div class="flex-shrink-0">
          <img src={{ImageHelpers.get_photo_url(@vm)}} class="rounded-full w-12 h-12 sm:w-16 sm:h-16 md:w-24 md:h-24 lg:w-32 lg:h-32" alt="" />
        </div>
        <div>
          <div class="h-full">
            <div class="flex flex-col h-full justify-center md:gap-3">
              <div>
                <div class="text-title6 font-title6 sm:text-title5 sm:font-title5 md:text-title4 md:font-title4 lg:text-title3 lg:font-title3 text-white">{{ title(@vm) }}</div>
              </div>
              <div>
                <div class="text-bodysmall sm:text-bodymedium lg:text-subhead font-subhead tracking-wider text-white">{{ subtitle(@vm) }}</div>
              </div>
            </div>
          </div>
        </div>
        <div class="flex-grow">
        </div>
        <div class="hidden sm:block">
          <DynamicButton vm={{ button_large(@vm) }} />
        </div>
        <div class="sm:hidden">
          <DynamicButton vm={{ button_small(@vm) }} />
        </div>
      </div>
    </div>
    """
  end
end
