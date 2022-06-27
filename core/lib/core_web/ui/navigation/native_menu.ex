defmodule CoreWeb.UI.Navigation.NativeMenu do
  @moduledoc """
    Vertical stacked menu used on the side
  """
  use CoreWeb.UI.Component

  alias CoreWeb.UI.Navigation.Menu

  prop(items, :any, required: true)
  prop(path_provider, :any, required: true)

  def render(assigns) do
    ~F"""
    <Menu items={@items} path_provider={@path_provider} />
    """
  end
end
