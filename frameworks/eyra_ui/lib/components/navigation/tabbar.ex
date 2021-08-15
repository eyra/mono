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
    <div class="relative">
      <div class="absolute top-0 left-0 w-full">
        <div class=" overflow-scroll scrollbar-hide">
          <div class="flex flex-row items-center h-navbar">
            <div class="flex-grow">
            </div>
            <div class="flex-wrap">
              <div class="flex flex-row items-center gap-6 sm:gap-10 h-full">
                <Context get={{tabs: tabs}}>
                  <For each={{ {tab, index} <- Enum.with_index(tabs) }}>
                    <div
                      x-on:mousedown="active_tab = {{ index }}"
                      class="flex-shrink-0 {{ side_padding(index, Enum.count(tabs)) }}"
                    >
                      <TabbarItem vm={{ Map.put(tab, :index, index) }} />
                    </div>
                  </For>
                </Context>
              </div>
            </div>
            <div class="flex-grow">
            </div>
          </div>
        </div>
        <Line />
      </div>
    </div>
    """
  end
end
