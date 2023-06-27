defmodule CoreWeb.UI.ProgressBar do
  @moduledoc """
    Progress bar capable of stacking multiple bars.
    The bars will be sorted on size and will be stacked from large to small.
  """
  use CoreWeb, :html

  defp hide(0, _), do: true
  defp hide(nil, _), do: true
  defp hide(_, %{size: 0}), do: true

  defp hide(total_size, %{size: size}) do
    size / total_size == 1
  end

  defp width(0, _), do: 0
  defp width(nil, _), do: 0
  defp width(_, %{size: 0}), do: 0

  defp width(total_size, %{size: size}) do
    size / total_size * 100
  end

  defp min_width(0, _, _, _index), do: "0px"
  defp min_width(_, _, %{size: 0}, _index), do: "0px"
  defp min_width(_, bars, _, index), do: "#{24 + 12 * (Enum.count(bars) - (index + 1))}px"

  defp color(%{color: color}), do: "bg-#{color}"

  defp sort_by_size(bars) do
    bars |> Enum.sort_by(& &1.size, :desc)
  end

  attr(:size, :integer, default: 0)
  attr(:bars, :list, default: [])
  attr(:bg_color, :string, default: "bg-grey4")

  def progress_bar(assigns) do
    ~H"""
    <div class="relative h-6">
      <div class={"absolute w-full h-6 rounded-full #{@bg_color}"}>
      </div>
      <%= for {bar, index} <- Enum.with_index(sort_by_size(@bars)) do %>
        <div class="absolute h-6 w-full">
          <div
            style={"min-width: #{min_width(@size, @bars, bar, index)}; width: #{width(@size, bar)}%"}
            class={"absolute h-6 rounded-full bg-white ml-2px #{hide(@size, bar)}"}
          />
          <div
            style={"min-width: #{min_width(@size, @bars, bar, index)}; width: #{width(@size, bar)}%"}
            class={"absolute h-6 rounded-full #{color(bar)}"}
          />
        </div>
      <% end %>
    </div>
    """
  end
end
