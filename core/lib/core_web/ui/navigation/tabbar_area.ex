defmodule CoreWeb.UI.Navigation.TabbarArea do
  @moduledoc false
  use CoreWeb.UI.Component

  prop(tabs, :list, required: true)

  slot(default, required: true)

  defp active_tab(tabs) do
    Enum.find_index(tabs, & &1.active) || 0
  end

  def render(assigns) do
    ~H"""
    <div x-data="{ active_tab: {{active_tab(@tabs)}} }" >
      <Context put={{tabs: @tabs}}>
        <slot />
      </Context>
    </div>
    """
  end
end
