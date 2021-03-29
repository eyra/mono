defmodule EyraUI.Grid.ImageGrid do
  @moduledoc false
  use Surface.Component

  @doc "The content"
  slot(default, required: true)

  def render(assigns) do
    ~H"""
    <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-10">
      <slot />
    </div>
    """
  end
end
