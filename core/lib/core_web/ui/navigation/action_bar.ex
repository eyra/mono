defmodule CoreWeb.UI.Navigation.ActionBar do
  @moduledoc false
  use CoreWeb.UI.Component

  alias CoreWeb.UI.Navigation.ActionMenu
  alias EyraUI.Line

  prop(right_bar_buttons, :list, default: [])
  prop(more_buttons, :list, default: [])

  slot(default, required: true)

  def render(assigns) do
    ~H"""
    <div class="relative">
      <div id="action_menu" class="hidden z-30 absolute right-14px -mt-6 top-navbar-height">
        <ActionMenu buttons={{ @more_buttons }} />
      </div>
      <div class="absolute top-0 left-0 w-full">
        <ContentArea>
          <div class="overflow-scroll scrollbar-hide">
            <div class="flex flex-row items-center h-navbar-height">
              <div class="flex-grow bg-grey3" :if={{ Enum.count(@right_bar_buttons) == 0 }} >
              </div>
              <div class="flex-grow">
                <slot/>
              </div>
              <div class="flex-wrap h-full" >
                <div class="flex flex-row gap-6 h-full">
                  <DynamicButton :for={{ button <- @right_bar_buttons }} vm={{ button }} />
                </div>
              </div>
            </div>
          </div>
        </ContentArea>
        <Line />
      </div>
    </div>
    """
  end
end
