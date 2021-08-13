defmodule EyraUI.Button.Action.Redirect do
  @moduledoc """
  Redirects to next live view
  """
  use Surface.Component
  alias Surface.Components.LiveRedirect

  prop(to, :string, required: true)
  slot(default, required: true)

  def render(assigns) do
    ~H"""
    <LiveRedirect to={{ @to }} class="cursor-pointer focus:outline-none" >
      <slot />
    </LiveRedirect>
    """
  end
end
