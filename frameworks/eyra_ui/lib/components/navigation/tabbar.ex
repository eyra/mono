defmodule EyraUI.Navigation.Tabbar do
  @moduledoc false
  use Surface.LiveComponent

  alias EyraUI.Line
  alias EyraUI.Navigation.TabbarItem

  defp side_padding(0, _), do: "pl-6"
  defp side_padding(index, count) when index == count - 1, do: "pr-6"
  defp side_padding(_index, _count), do: ""

  def render(assigns) do
    ~H"""
    <div>
      <div class="overflow-scroll scrollbar-hide">
        <div class="sm:flex flex-row items-center justify-center h-full">
          <div class="flex flex-row items-center gap-10 h-navbar">
            <Context get={{tabs: tabs}}>
              <For each={{ {tab, index} <- Enum.with_index(tabs) }}>
                <div
                  x-on:mousedown="active_tab = {{ index }}"
                  class="flex-nowrap flex-shrink-0 {{ side_padding(index, Enum.count(tabs)) }}"
                >
                  <TabbarItem vm={{ Map.put(tab, :index, index) }} />
                </div>
              </For>
            </Context>
          </div>
        </div>
      </div>
      <Line />
    </div>
    """
  end
end
