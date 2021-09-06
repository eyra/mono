defmodule CoreWeb.UI.Navigation.TabbarArea do
  @moduledoc false
  use CoreWeb.UI.Component

  prop(tabs, :list, required: true)

  slot(default, required: true)

  def render(assigns) do
    ~H"""
    <div>
      <Context put={{tabs: @tabs}}>
        <slot />
      </Context>
    </div>
    """
  end
end
