defmodule CoreWeb.UI.Navigation.TabbarItem do
  @moduledoc """
    Item that can be used in Menu or Navbar
  """
  use EyraUI.Component

  defviewmodel(
    id: nil,
    title: nil,
    ready?: true,
    index: nil
  )

  prop(tabbar, :string, required: true)
  prop(opts, :string, default: "")
  prop(vm, :any, required: true)

  def center_correction_for_number(1), do: "mr-1px"
  def center_correction_for_number(4), do: "mr-1px"
  def center_correction_for_number(_), do: ""

  def icon_text(_, %{ready?: false}), do: "!"
  def icon_text(index, _), do: index + 1

  def active_icon(_), do: "bg-primary text-white"

  def idle_icon(%{ready?: false}), do: "bg-warning text-white"
  def idle_icon(_), do: "bg-grey5 text-grey2"

  def active_title(_), do: "text-primary"

  def idle_title(%{ready?: false}), do: "text-warning"
  def idle_title(_), do: "text-grey2"

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
          idle-class={{idle_icon(@vm)}}
          active-class={{active_icon(@vm)}}
        >
          <span class="text-center w-full mt-1px {{center_correction_for_number(icon_text(index(@vm), @vm))}}">{{ icon_text( index(@vm), @vm) }}</span>
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
              idle-class={{idle_title(@vm)}}
              active-class={{active_title(@vm)}}
            >
              {{ title(@vm) }}
            </div>
          </div>
        </div>
      </div>
    """
  end
end
