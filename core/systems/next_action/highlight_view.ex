defmodule Systems.NextAction.HighlightView do
  use CoreWeb.UI.Component
  alias Systems.NextAction

  prop(vm, :any, required: true)

  def render(assigns) do
    ~H"""
    <NextAction.View vm={{ Map.put(@vm, :highlighted?, true) }}  />
    """
  end
end
