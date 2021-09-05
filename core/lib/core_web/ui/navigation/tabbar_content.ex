defmodule CoreWeb.UI.Navigation.TabbarContent do
  @moduledoc false
  use CoreWeb.UI.Component

  alias EyraUI.Dynamic
  alias CoreWeb.UI.Navigation.Tab

  def render(assigns) do
    ~H"""
      <div class="h-navbar-height"></div>
      <Context get={{tabs: tabs}}>
        <For each={{ {tab, index} <- Enum.with_index(tabs) }} >
          <Tab index= {{ index }}>
            <Dynamic component={{ tab.component }} props={{ %{id: tab.id, props: tab.props } }}/>
          </Tab>
        </For>
      </Context>
    """
  end
end
