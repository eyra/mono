defmodule EyraUI.Grid.DynamicGrid do
  use Surface.Component

  @doc "The content"
  slot default, required: true

  def render(assigns) do
    ~H"""
    <div class="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
      <slot />
    </div>
    """
  end
end
