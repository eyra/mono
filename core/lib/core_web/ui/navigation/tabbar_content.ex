defmodule CoreWeb.UI.Navigation.TabbarContent do
  @moduledoc false
  use CoreWeb.UI.Component

  alias Frameworks.Pixel.Dynamic
  alias CoreWeb.UI.Navigation.Tab

  def render(assigns) do
    ~H"""
      <div class="h-navbar-height"></div>
      <Context get={{tabs: tabs}}>
        <For each={{ tab <- tabs }} >
          <Tab id={{ tab.id }}>
            <Dynamic component={{ tab.component }} props={{ %{id: tab.id, props: tab.props } }}/>
          </Tab>
        </For>
      </Context>
    """
  end
end
