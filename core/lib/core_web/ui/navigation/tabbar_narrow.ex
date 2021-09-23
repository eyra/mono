defmodule CoreWeb.UI.Navigation.TabbarNarrow do
  @moduledoc false
  use CoreWeb.UI.LiveComponent

  alias CoreWeb.UI.Navigation.{TabbarDropdown, TabbarItem}

  def render(assigns) do
    ~H"""
    <Context get={{tabs: tabs}}>
      <div id="tabbar_dropdown" class="absolute left-0 top-navbar-height w-full h-full">
        <TabbarDropdown />
      </div>
      <div id="tabbar_narrow" phx-hook="Toggle" target="tabbar_dropdown" class="flex flex-row cursor-pointer items-center h-full w-full">
        <div class="flex-shrink-0">
          <For each={{ {tab, index} <- Enum.with_index(tabs) }}>
            <div class="flex-shrink-0">
              <TabbarItem tabbar="narrow" opts="hide-when-idle" vm={{ Map.merge(tab, %{index: index}) }} />
            </div>
          </For>
        </div>
        <div class="flex-grow">
        </div>
        <div>
          <img src="/images/icons/dropdown.svg" alt="Show tabbar dropdown" />
        </div>
      </div>
    </Context>
    """
  end
end
