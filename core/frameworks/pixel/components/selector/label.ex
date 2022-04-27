defmodule Frameworks.Pixel.Selector.Label do
  @moduledoc false
  use Frameworks.Pixel.Component

  prop(item, :map, required: true)
  prop(multiselect?, :boolean, default: true)
  prop(background, :atom, default: :light)

  def render(assigns) do
    ~F"""
    <div
      :class="{ 'bg-primary text-white': active, 'bg-grey5 text-grey2': !active}"
      class="rounded-full px-6 py-3 text-label font-label select-none"
    >
      {@item.value}
    </div>
    """
  end
end
