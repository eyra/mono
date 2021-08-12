defmodule EyraUI.Selector.Label do
  @moduledoc false
  use EyraUI.Component

  prop(item, :map, required: true)

  def render(assigns) do
    ~H"""
    <div
      :class="{ 'bg-primary text-white': active, 'bg-grey5 text-grey2': !active}"
      class="rounded-full px-6 py-3 text-label font-label select-none"
    >
      {{ @item.value }}
    </div>
    """
  end
end
