defmodule EyraUI.Container.Bar do
  @moduledoc """
  Container that makes the content appear centralized by adding margin to the right to adjust for the left sidebar.
  """
  use Surface.Component

  alias EyraUI.Spacing

  slot(items, required: true)
  prop(gap, :string, default: "XS")

  def render(assigns) do
    ~H"""
    <div class="flex flex-row items-center">
    <For each={{ {_, index} <- Enum.with_index(@items) }}>
      <slot name="items" index={{ index }} />
      <Spacing value="{{@gap}}" direction="l" />
    </For>
    </div>
    """
  end
end

defmodule EyraUI.Container.BarItem do
  @moduledoc """
  Container that makes the content appear centralized by adding margin to the right to adjust for the left sidebar.
  """
  use Surface.Component, slot: "items"

  @doc "The content"
  slot(default, required: true)
end
