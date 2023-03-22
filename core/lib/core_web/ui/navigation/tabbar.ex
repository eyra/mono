defmodule CoreWeb.UI.Navigation.Tabbar do
  @moduledoc false
  use CoreWeb.UI.Component

  prop(id, :any, required: true)
  prop(type, :atom, default: :seperated)
  prop(initial_tab, :any)
  prop(size, :atom, default: :wide)

  alias CoreWeb.UI.Navigation.{TabbarWide, TabbarNarrow}

  defp shape(%{size: :wide, type: :segmented}), do: "rounded-full overflow-hidden h-10 bg-grey5"
  defp shape(%{size: :narrow}), do: "w-full"
  defp shape(_), do: ""

  def render(assigns) do
    ~F"""
    <div id={@id} data-initial-tab={@initial_tab} phx-hook="Tabbar" class={"#{shape(assigns)}"}>
      <TabbarWide :if={@size == :wide} id={:tabbar_wide} type={@type} />
      <TabbarNarrow :if={@size == :narrow} id={:tabbar_narrow} />
    </div>
    """
  end
end
