defmodule CoreWeb.UI.Navigation.Menu do
  @moduledoc """
    Vertical stacked menu used on the side
  """
  use CoreWeb.UI.Component

  alias CoreWeb.UI.Navigation.MenuItem

  prop(items, :any, required: true)
  prop(path_provider, :any, required: true)
  prop(size, :atom, default: :wide)

  defp has_home?(%{home: home}) when home != nil, do: true
  defp has_home?(_), do: false

  defp top(%{top: top}) when top != nil, do: top
  defp top(_), do: []

  defp bottom(%{bottom: bottom}) when bottom != nil, do: bottom
  defp bottom(_), do: []

  defp align(:narrow), do: "items-center"
  defp align(:wide), do: "items-left"

  def render(assigns) do
    ~F"""
    <div class="h-full">
      <div class={"flex flex-col h-full #{align(@size)}"} >
        <div class="flex-wrap" :if={has_home?(@items)} >
           <div class="mb-8">
              <MenuItem vm={@items.home} size={@size} />
            </div>
        </div>
        <div class="flex-wrap">
          <div :for={item <- top(@items)} class="mb-2">
            <MenuItem vm={item} size={@size} />
          </div>
        </div>
        <div class="flex-grow">
        </div>
        <div class="flex-wrap">
          <div :for={item <- bottom(@items)} class="mb-2" >
            <MenuItem vm={item} size={@size} />
          </div>
        </div>
      </div>
    </div>
    """
  end
end
