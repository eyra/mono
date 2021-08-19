defmodule CoreWeb.UI.Navigation.Navbar do
  @moduledoc """
    Horizontal menu used on top of the page
  """
  use CoreWeb.UI.Component

  alias CoreWeb.UI.Navigation.MenuItem
  alias EyraUI.Alignment.HorizontalCenter

  prop(items, :any, required: true)
  prop(path_provider, :any, required: true)

  defp has_home?(%{home: home}) when home != nil, do: true
  defp has_home?(_), do: false

  defp left(%{left: left}) when left != nil, do: left
  defp left(_), do: []

  defp right(%{right: right}) when right != nil, do: right
  defp right(_), do: []

  def render(assigns) do
    ~H"""
    <div class="h-topbar sm:h-topbar-sm lg:h-topbar-lg">
      <HorizontalCenter>
        <div class="flex-wrap" :if={{ has_home?(@items) }} >
          <div class="ml-6 md:ml-0 mr-8">
            <MenuItem vm={{ @items.home }} path_provider={{@path_provider}}/>
          </div>
        </div>
        <div :for={{ item <- left(@items)  }} class="mr-1">
          <MenuItem vm={{item}} path_provider={{@path_provider}}/>
        </div>
        <div class="flex-grow">
        </div>
        <div :for={{ item <- right(@items) }} class="ml-1" >
          <MenuItem vm={{item}} path_provider={{@path_provider}} />
        </div>
      </HorizontalCenter>
    </div>
    """
  end
end
