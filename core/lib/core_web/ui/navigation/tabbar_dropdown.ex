defmodule CoreWeb.UI.Navigation.TabbarDropdown do
  use CoreWeb.UI.Component

  alias CoreWeb.UI.Navigation.TabbarItem
  alias EyraUI.Line

  prop(alpine_id, :string, default: "dropdown")

  def render(assigns) do
    ~H"""
    <Context get={{tabs: tabs}}>
      <div>
        <Line />
        <div x-on:click.away="{{@alpine_id}} = false" class="flex flex-col items-left p-6 gap-6 w-full bg-white drop-shadow-2xl">
          <For each={{ {tab, index} <- Enum.with_index(tabs) }}>
            <div
              x-on:mousedown="active_tab = {{ index }}; dropdown = false"
              class="flex-shrink-0"
            >
              <TabbarItem vm={{ Map.put(tab, :index, index) }} />
            </div>
          </For>
        </div>
        <Line />
        <div class="h-5 bg-gradient-to-b from-black opacity-shadow">
        </div>
      </div>
    </Context>
    """
  end
end
