defmodule CoreWeb.UI.Navigation.ActionBar do
  @moduledoc false
  use CoreWeb.UI.Component

  alias CoreWeb.UI.Navigation.ActionMenu
  alias Frameworks.Pixel.Line

  prop(right_bar_buttons, :list, default: [])
  prop(more_buttons, :list, default: [])
  prop(size, :atom, default: :wide)
  prop(hide_seperator, :boolean, default: false)

  slot(default)

  defp centralize?(%{size: :wide, right_bar_buttons: right_bar_buttons}),
    do: right_bar_buttons == []

  defp centralize?(_), do: false

  defp has_right_bar_buttons?(%{right_bar_buttons: right_bar_buttons}) do
    !Enum.empty?(right_bar_buttons)
  end

  defp has_right_bar_buttons?(_), do: false

  def render(assigns) do
    ~F"""
    <div class="relative">
      <div id="action_menu" class="hidden z-50 absolute right-14px -mt-6 top-navbar-height">
        <ActionMenu buttons={@more_buttons} />
      </div>
      <div class="absolute top-0 left-0 w-full">
        <ContentArea>
          <div class="overflow-scroll scrollbar-hide w-full">
            <div class="flex flex-row items-center w-full h-navbar-height">
              <div class="flex-grow" :if={centralize?(assigns)}>
              </div>
              <div class={"#{if centralize?(assigns) do
                "flex-wrap"
              else
                "flex-grow"
              end}"}>
                <#slot /> <!-- tabbar -->
              </div>
              <div class="flex-wrap px-4" :if={has_right_bar_buttons?(assigns) && !@hide_seperator}>
                <img src="/images/icons/bar_seperator.svg" alt="">
              </div>
              <div class="flex-wrap h-full" :if={has_right_bar_buttons?(assigns)}>
                <div class="flex flex-row gap-6 h-full">
                  <DynamicButton :for={button <- @right_bar_buttons} vm={button} />
                </div>
              </div>
              <div class="flex-grow" :if={centralize?(assigns)}>
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
