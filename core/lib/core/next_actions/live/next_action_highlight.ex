defmodule Core.NextActions.Live.NextActionHighlight do
  use Surface.Component
  alias Core.NextActions.Live.NextAction

  prop(vm, :any, required: true)

  def render(assigns) do
    ~H"""
    <NextAction vm={{ Map.put(@vm, :highlighted?, true) }}  />
    """
  end
end
