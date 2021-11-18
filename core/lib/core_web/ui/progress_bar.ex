defmodule CoreWeb.UI.ProgressBar do
  @moduledoc """
    Circle with a number
  """
  use EyraUI.Component

  defviewmodel(
    size: nil,
    bars: nil,
    bg_color: "bg-grey4"
  )

  prop(vm, :any, required: true)

  defp hide(total_size, %{size: size}) do
    size / total_size == 1
  end

  defp width(total_size, %{size: size}) do
    size / total_size * 100
  end

  defp color(%{color: color}), do: "bg-#{color}"

  def render(assigns) do
    ~H"""
    <div class="relative h-6 mb-12">
      <div class="absolute w-full h-6 rounded-full {{ bg_color(@vm) }}">
      </div>
      <div :for={{ bar <- bars(@vm) }} class="absolute h-6 w-full">
        <div style="width: {{width(size(@vm), bar)}}%" class="absolute h-6 rounded-full bg-white ml-2px {{ hide(size(@vm), bar) }}"></div>
        <div style="width: {{width(size(@vm), bar)}}%" class="absolute h-6 rounded-full {{color(bar)}}"></div>
      </div>
    </div>
    """
  end
end
