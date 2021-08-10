defmodule EyraUI.Button.Action.Redirect do
  @moduledoc """
  Redirects to next live view
  """
  use Surface.Component
  alias Surface.Components.LiveRedirect

  prop(path, :string, required: true)
  slot(default, required: true)

  def render(assigns) do
    ~H"""
    <LiveRedirect to={{ @path }} >
      <slot />
    </LiveRedirect>>
    """
  end
end
