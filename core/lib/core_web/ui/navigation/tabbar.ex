defmodule CoreWeb.UI.Navigation.Tabbar do
  @moduledoc false
  use CoreWeb.UI.Component

  prop(initial_tab, :integer, required: true)
  prop(size, :atom, default: :wide)

  alias CoreWeb.UI.Navigation.{TabbarWide, TabbarNarrow}

  def render(assigns) do
    ~H"""
    <div id="tabbar" data-initial-tab={{@initial_tab}} phx-hook="Tabbar">
      <TabbarWide :if={{ @size == :wide }} id={{ :tabbar_wide }} />
      <TabbarNarrow :if={{ @size == :narrow }} id={{ :tabbar_narrow }} />
    </div>
    """
  end
end
