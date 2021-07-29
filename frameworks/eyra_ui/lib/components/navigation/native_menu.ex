defmodule EyraUI.Navigation.NativeMenu do
  @moduledoc """
    Vertical stacked menu used on the side
  """
  use Surface.Component

  alias EyraUI.Navigation.Menu

  prop(items, :any, required: true)
  prop(path_provider, :any, required: true)

  def render(assigns) do
    ~H"""
    <Menu items={{@items}} path_provider={{@path_provider}}/>
    """
  end
end
