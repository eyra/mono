defmodule EyraUI.Text.BodyLarge do
  use Surface.Component

  slot default, required: true

  def render(assigns) do
    ~H"""
    <div class="flex-wrap text-grey1 text-bodylarge font-body mt-6 lg:mt-10">
      <slot />
    </div>
    """
  end
end
