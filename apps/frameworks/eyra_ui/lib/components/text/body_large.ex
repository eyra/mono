defmodule EyraUI.Text.BodyLarge do
  @moduledoc """
  The body large is to be used for ...?
  """
  use Surface.Component

  slot(default, required: true)

  def render(assigns) do
    ~H"""
    <div class="flex-wrap text-grey1 text-bodylarge font-body">
      <slot />
    </div>
    """
  end
end
