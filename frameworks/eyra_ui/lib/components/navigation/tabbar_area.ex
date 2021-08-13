defmodule EyraUI.Navigation.TabbarArea do
  @moduledoc false
  use Surface.Component

  prop(tabs, :list, required: true)

  slot(default, required: true)

  def render(assigns) do
    ~H"""
    <div x-data="{ active_tab: 0 }" >
      <Context put={{tabs: @tabs}}>
        <slot />
      </Context>
    </div>
    """
  end
end
