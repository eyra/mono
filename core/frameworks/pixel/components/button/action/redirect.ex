defmodule Frameworks.Pixel.Button.Action.Redirect do
  @moduledoc """
  Redirects to next live view
  """
  use Frameworks.Pixel.Component
  alias Surface.Components.LiveRedirect

  slot(default, required: true)

  prop(vm, :map, required: true)

  defviewmodel(to: nil)

  def render(assigns) do
    ~F"""
    <LiveRedirect to={to(@vm)} class="cursor-pointer focus:outline-none" >
      <#slot />
    </LiveRedirect>
    """
  end
end
