defmodule CoreWeb.UI.Navigation.TabbarContent do
  @moduledoc false
  use CoreWeb.UI.Component

  alias CoreWeb.UI.Navigation.Tab

  data(tabs, :any, from_context: :tabs)

  def render(assigns) do
    ~F"""
    <div>
      <div class="h-navbar-height" />
      {#for tab <- @tabs}
        <Tab id={tab.id}>
          <Dynamic.LiveComponent id={tab.id} module={tab.component} props={tab.props} />
        </Tab>
      {/for}
    </div>
    """
  end
end
