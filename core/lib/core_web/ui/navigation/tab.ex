defmodule CoreWeb.UI.Navigation.Tab do
  @moduledoc false
  use CoreWeb.UI.Component

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
