defmodule CoreWeb.UI.Navigation.Tabbar do
  @moduledoc false
  use CoreWeb.UI.Component

  prop(vm, :map, required: true)

  defviewmodel(
    type: nil,
    initial_tab: nil,
    size: :wide
  )

  alias CoreWeb.UI.Navigation.{TabbarWide, TabbarNarrow}

  defp shape(%{size: :wide, type: :segmented}), do: "rounded-full overflow-hidden h-10 bg-grey5"
  defp shape(%{size: :narrow}), do: "w-full"
  defp shape(_), do: ""

  def render(assigns) do
    ~F"""
      <div id="tabbar" data-initial-tab={initial_tab(@vm)} phx-hook="Tabbar" class={"#{shape(@vm)}"}>
        <TabbarWide :if={size(@vm) == :wide} id={:tabbar_wide} vm={@vm}/>
        <TabbarNarrow :if={size(@vm) == :narrow} id={:tabbar_narrow} />
      </div>
    """
  end
end
