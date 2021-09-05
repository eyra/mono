defmodule CoreWeb.UI.Navigation.TabbarWide do
  @moduledoc false
  use CoreWeb.UI.LiveComponent

  alias CoreWeb.UI.Navigation.TabbarItem

  def render(assigns) do
    ~H"""
    <Context get={{tabs: tabs}}>
      <div class="flex flex-row items-center gap-6 h-full">
        <For each={{ {tab, index} <- Enum.with_index(tabs) }}>
          <div
            x-on:mousedown="active_tab = {{ index }}"
            class="flex-shrink-0"
          >
            <TabbarItem vm={{ Map.put(tab, :index, index) }} />
          </div>
        </For>
      </div>
    </Context>
    """
  end
end
