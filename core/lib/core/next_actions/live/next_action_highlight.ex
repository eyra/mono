defmodule Core.NextActions.Live.NextActionHighlight do
  use Surface.Component
  alias Core.NextActions.Live.NextAction

  prop(actions, :list, required: true)

  def render(assigns) do
    ~H"""
    <NextAction :for={{action <- @actions}}
    title={{action.title}} description={{action.description}} cta={{action.cta}} url={{action.url}} />
    """
  end
end
