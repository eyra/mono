defmodule CoreWeb.UI.Navigation.TabbarWide do
  @moduledoc false
  use CoreWeb.UI.LiveComponent

  alias CoreWeb.UI.Navigation.TabbarItem

  prop(vm, :map, required: true)

  defviewmodel(type: :seperated)

  defp tab_vm(:seperated, tab, index), do: Map.merge(tab, %{type: :seperated, index: index})
  defp tab_vm(:segmented, tab, _), do: Map.put(tab, :type, :segmented)

  defp gap(:seperated), do: "gap-6"
  defp gap(:segmented), do: "gap-0"

  def render(assigns) do
    ~H"""
    <Context get={{tabs: tabs}}>
      <div class="flex flex-row items-center h-full {{gap(type(@vm))}}">
        <For each={{ {tab, index} <- Enum.with_index(tabs) }}>
          <div class="flex-shrink-0 h-full">
            <TabbarItem tabbar="wide" vm={{ tab_vm(type(@vm), tab, index) }} />
          </div>
        </For>
      </div>
    </Context>
    """
  end
end
