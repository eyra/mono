defmodule CoreWeb.UI.Navigation.TabbarContent do
  @moduledoc false
  use CoreWeb.UI.Component

  alias CoreWeb.UI.Navigation.Tab

  def render(assigns) do
    ~F"""
      <div class="h-navbar-height"></div>
      <Context get={tabs: tabs}>
        {#for tab <- tabs}
          <Tab id={tab.id}>
            <Dynamic.LiveComponent id={tab.id} module={tab.component} props={tab.props} />
          </Tab>
        {/for}
      </Context>
    """
  end
end
