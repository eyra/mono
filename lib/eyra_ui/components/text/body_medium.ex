defmodule EyraUI.Text.BodyMedium do
  @moduledoc """
  The body medium is to be used for ...?
  """
  use Surface.Component

  slot default, required: true

  def render(assigns) do
    ~H"""
    <div class="flex-wrap text-grey1 text-bodymedium font-body">
      <slot />
    </div>
    """
  end
end
