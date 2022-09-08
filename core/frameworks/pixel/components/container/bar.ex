defmodule Frameworks.Pixel.Container.Bar do
  @moduledoc """
  Container that makes the content appear centralized by adding margin to the right to adjust for the left sidebar.
  """
  use Surface.Component

  alias Frameworks.Pixel.Spacing

  slot(items, required: true)
  prop(gap, :string, default: "XS")

  def render(assigns) do
    ~F"""
    <div class="flex flex-row items-center">
      {#for item <- @items}
        <#slot {item} />
        <Spacing value={"#{@gap}"} direction="l" />
      {/for}
    </div>
    """
  end
end

defmodule Frameworks.Pixel.Container.BarItem do
  @moduledoc """
  Container that makes the content appear centralized by adding margin to the right to adjust for the left sidebar.
  """
  use Surface.Component, slot: "items"

  @doc "The content"
  slot(default, required: true)
end
