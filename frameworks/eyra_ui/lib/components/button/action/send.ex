defmodule EyraUI.Button.Action.Send do
  @moduledoc """
  Sends phoenix event to target (live component or live view)
  """
  use Surface.Component

  prop(event, :string, required: true)
  prop(target, :any)

  slot(default, required: true)

  def render(assigns) do
    ~H"""
    <button phx-target={{@target}} phx-click={{ @event }} class="cursor-pointer focus:outline-none">
      <slot />
    </button>
    """
  end
end
