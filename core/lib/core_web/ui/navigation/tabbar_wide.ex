defmodule CoreWeb.UI.Navigation.TabbarWide do
  @moduledoc false
  use CoreWeb.UI.LiveComponent

  alias CoreWeb.UI.Navigation.TabbarItem

  prop(type, :atom, default: :seperated)

  data(tabs, :any, from_context: :tabs)

  defp tab_vm(:seperated, tab, index), do: Map.merge(tab, %{type: :seperated, index: index})
  defp tab_vm(:segmented, tab, _), do: Map.put(tab, :type, :segmented)

  defp gap(:seperated), do: "gap-6"
  defp gap(:segmented), do: "gap-0"

  def render(assigns) do
    ~F"""
    <div class={"flex flex-row items-center h-full #{gap(@type)}"}>
      {#for {tab, index} <- Enum.with_index(@tabs)}
        <div class="flex-shrink-0 h-full">
          <TabbarItem tabbar="wide" vm={tab_vm(@type, tab, index)} />
        </div>
      {/for}
    </div>
    """
  end
end
