defmodule EyraUI.Navigation.Navbar do
  @moduledoc """
    Horizontal menu used on top of the page
  """
  use Surface.Component

  alias EyraUI.Navigation.MenuItem
  alias EyraUI.Alignment.HorizontalCenter

  prop(items, :any, required: true)
  prop(path_provider, :any, required: true)

  defp left(%{first: left}), do: left
  defp left(_), do: []

  defp right(%{second: right}), do: right
  defp right(_), do: []

  def render(assigns) do
    ~H"""
    <div class="h-topbar sm:h-topbar-sm lg:h-topbar-lg">
      <HorizontalCenter>
        <div class="ml-1 sm:ml-4 lg:ml-0 mr-8">
          <MenuItem view_model={{ @items.home }} path_provider={{@path_provider}}/>
        </div>
        <div :for={{ item <- left(@items)  }} class="mr-1">
          <MenuItem view_model={{item}} path_provider={{@path_provider}}/>
        </div>
        <div class="flex-grow">
        </div>
        <div :for={{ item <- right(@items) }} class="ml-1" >
          <MenuItem view_model={{item}} path_provider={{@path_provider}} />
        </div>
      </HorizontalCenter>
    </div>
    """
  end
end
