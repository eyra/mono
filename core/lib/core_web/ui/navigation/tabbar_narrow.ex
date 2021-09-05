defmodule CoreWeb.UI.Navigation.TabbarNarrow do
  @moduledoc false
  use CoreWeb.UI.LiveComponent

  alias CoreWeb.UI.Navigation.{TabbarDropdown, TabbarItem}

  def render(assigns) do
    ~H"""
    <Context get={{tabs: tabs}}>
      <div x-show="dropdown" class="absolute left-0 top-navbar-height w-full h-full">
        <TabbarDropdown />
      </div>
      <div x-on:click="dropdown = true" class="flex flex-row cursor-pointer items-center h-full w-full">
        <div class="flex-shrink-0">
          <For each={{ {tab, index} <- Enum.with_index(tabs) }}>
            <div x-show="active_tab == {{ index }}" class="flex-shrink-0">
              <TabbarItem vm={{ Map.put(tab, :index, index) }} />
            </div>
          </For>
        </div>
        <div class="flex-grow">
        </div>
        <div>
          <img src="/images/icons/dropdown.svg" />
        </div>
        <div class="px-4">
          <img src="/images/icons/bar_seperator.svg" />
        </div>
      </div>
    </Context>
    """
  end
end
