defmodule EyraUI.Navigation.TabbarContent do
  @moduledoc false
  use Surface.Component

  alias EyraUI.Dynamic
  alias EyraUI.Navigation.Tab

  prop(user, :map, required: true)

  def render(assigns) do
    ~H"""
      <div class="h-navbar"></div>
      <Context get={{tabs: tabs}}>
        <For each={{ {tab, index} <- Enum.with_index(tabs) }} >
          <Tab index= {{ index }}>
            <Dynamic component={{ tab.component }} props={{ %{id: tab.id, user: @user } }}/>
          </Tab>
        </For>
      </Context>
    """
  end
end
