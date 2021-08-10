defmodule EyraUI.Navigation.Tab do
  @moduledoc false
  use Surface.Component

  prop(index, :integer, required: true)

  slot(default, required: true)

  def render(assigns) do
    ~H"""
    <div x-show="active_tab == {{ @index }}">
      <slot />
    </div>
    """
  end
end
