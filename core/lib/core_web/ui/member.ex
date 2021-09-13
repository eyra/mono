defmodule CoreWeb.UI.Member do
  @moduledoc """
    Label with a pill formed background.
  """
  use CoreWeb.UI.Component

  alias EyraUI.Button.DynamicButton
  alias EyraUI.Text.{Title3, SubHead}
  alias EyraUI.Wrap

  defviewmodel(
    title: nil,
    subtitle: nil,
    photo_url: nil,
    button: nil
  )

  prop(vm, :map, required: true)

  def render(assigns) do
    ~H"""
    <div class="flex flex-row gap-4 md:gap-8 h-full">
      <div class="flex-shrink-0">
        <img src={{ photo_url(@vm)}} class="rounded-full w-16 h-16 md:w-24 md:h-24 lg:w-32 lg:h-32" />
      </div>
      <div>
        <div class="h-full">
          <div class="flex flex-col h-full justify-center md:gap-3">
            <div>
              <Title3 margin="">{{ title(@vm) }}</Title3>
            </div>
            <div>
              <SubHead>{{ subtitle(@vm) }}</SubHead>
            </div>
          </div>
        </div>
      </div>
      <div class="flex-grow">
      </div>
      <div class="hidden md:block">
        <DynamicButton vm={{ button(@vm) }} />
      </div>
    </div>
    <div class="md:hidden mt-8">
      <Wrap>
        <DynamicButton vm={{ button(@vm) }} />
      </Wrap>
    </div>
    """
  end
end
