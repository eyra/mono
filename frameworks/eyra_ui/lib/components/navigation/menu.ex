defmodule EyraUI.Navigation.Menu do
  @moduledoc """
    Vertical stacked menu used on the side
  """
  use Surface.Component

  alias EyraUI.Navigation.MenuItem

  prop(items, :any, required: true)
  prop(path_provider, :any, required: true)

  defp has_home?(%{home: home}) when home != nil, do: true
  defp has_home?(_), do: false

  defp top(%{top: top}) when top != nil, do: top
  defp top(_), do: []

  defp bottom(%{bottom: bottom}) when bottom != nil, do: bottom
  defp bottom(_), do: []

  def render(assigns) do
    ~H"""
    <div class="h-full">
      <div class="flex flex-col h-full">
        <div class="flex-wrap" :if={{ has_home?(@items) }} >
           <div class="mb-8">
            <MenuItem vm={{ @items.home }} path_provider={{@path_provider}} />
            </div>
        </div>
        <div class="flex-wrap">
          <div :for={{ item <- top(@items) }} class="mb-2">
            <MenuItem vm={{item}} path_provider={{@path_provider}} />
          </div>
        </div>
        <div class="flex-grow">
        </div>
        <div class="flex-wrap">
          <div :for={{ item <- bottom(@items) }} class="mb-2" >
            <MenuItem vm={{item}} path_provider={{@path_provider}} />
          </div>
        </div>
      </div>
    </div>
    """
  end
end
