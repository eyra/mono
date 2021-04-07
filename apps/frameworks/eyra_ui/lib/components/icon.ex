defmodule EyraUI.Icon do
  @moduledoc """
    Round icon with grey border
  """
  use Surface.Component

  prop(size, :string, required: true)
  prop(src, :string, required: true)

  defp size("L"), do: "h-21 w-21"
  defp size("S"), do: "h-14 w-14"

  def render(assigns) do
    ~H"""
    <div class="{{size(@size)}} rounded-full bg-white border-2 border-grey4 border-opacity-100">
      <img class="rounded-full" src={{@src}}/>
    </div>
    """
  end
end
