defmodule CoreWeb.UI.Navigation.TabbarItem do
  @moduledoc """
    Item that can be used in Menu or Navbar
  """
  use EyraUI.Component

  defviewmodel(
    id: nil,
    title: nil,
    index: nil
  )

  prop(vm, :any, required: true)

  def render(assigns) do
    ~H"""
      <div class="flex flex-row items-center justify-start rounded-full focus:outline-none cursor-pointer">
        <div
          :if={{ has_index?(@vm) }}
          class="w-8 h-8 font-label text-label rounded-full flex items-center"
          :class="{ 'bg-primary text-white': active_tab == {{ index(@vm) }}, 'bg-grey5 text-grey2': active_tab != {{ index(@vm) }} }"
        >
          <div class="text-center w-full mt-1px">{{ index(@vm)+1 }}</div>
        </div>
        <div
          :if={{ has_title?(@vm) && has_index?(@vm) }}
          class="ml-2 sm:ml-3"
        >
        </div>
        <div :if={{ has_title?(@vm) }}>
          <div class="flex flex-col items-center justify-center">
            <div
              class="text-button font-button mt-1px"
              :class="{ 'text-primary': active_tab == {{ index(@vm) }}, 'text-grey2': active_tab != {{ index(@vm) }} }"
            >
              {{ title(@vm) }}
            </div>
          </div>
        </div>
      </div>
    """
  end
end
