defmodule EyraUI.Button.Action.Send do
  @moduledoc """
  Sends phoenix event to target (live component or live view)
  """
  use EyraUI.Component

  prop(vm, :map, required: true)

  defviewmodel(
    event: nil,
    target: ""
  )

  slot(default, required: true)

  def render(assigns) do
    ~H"""
    <button phx-target={{target(@vm)}} phx-click={{ event(@vm) }} class="cursor-pointer focus:outline-none">
      <slot />
    </button>
    """
  end
end
