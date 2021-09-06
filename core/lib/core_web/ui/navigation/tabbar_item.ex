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

  prop(tabbar, :string, required: true)
  prop(opts, :string, default: "")
  prop(vm, :any, required: true)

  def center_correction_for_number(1), do: "mr-1px"
  def center_correction_for_number(4), do: "mr-1px"
  def center_correction_for_number(_), do: ""

  def render(assigns) do
    ~H"""
      <div
        id="tabbar-{{@tabbar}}-{{id(@vm)}}"
        tab-id={{ id(@vm) }}
        phx-hook="TabbarItem"
        class="tabbar-item flex flex-row items-center justify-start rounded-full focus:outline-none cursor-pointer {{@opts}}"
      >
        <div
          :if={{ has_index?(@vm) }}
          class="icon w-6 h-6 font-caption text-caption rounded-full flex items-center"
          idle-class="bg-grey5 text-grey2"
          active-class="bg-primary text-white"
        >
          <div class="text-center w-full mt-1px {{center_correction_for_number(index(@vm)+1)}}">{{ index(@vm)+1 }}</div>
        </div>
        <div
          :if={{ has_title?(@vm) && has_index?(@vm) }}
          class="ml-3"
        >
        </div>
        <div :if={{ has_title?(@vm) }}>
          <div class="flex flex-col items-center justify-center">
            <div
              class="title text-button font-button mt-1px"
              idle-class="text-grey2"
              active-class="text-primary"
            >
              {{ title(@vm) }}
            </div>
          </div>
        </div>
      </div>
    """
  end
end
