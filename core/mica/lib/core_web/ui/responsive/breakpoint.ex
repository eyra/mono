defmodule CoreWeb.UI.Responsive.Breakpoint do
  @breakpoints [
    min: 0,
    xs: 320,
    sm: 640,
    md: 768,
    lg: 1024,
    xl: 1280,
    hd: 1366,
    fhd: 1920,
    qhd: 2560,
    uhd4k: 3840,
    uhd8k: 7680,
    max: 2_147_483_647
  ]

  def bp(viewport) do
    breakpoint(viewport)
  end

  defp width_for(break_value) do
    Keyword.get(@breakpoints, break_value)
  end

  def breakpoint(%{"width" => width}) do
    break_ranges = zip_shift_left(break_values())

    {from, till} =
      break_ranges
      |> Enum.reverse()
      |> Enum.find(fn {from, _till} -> width >= width_for(from) end)

    {from, percentage(width, width_for(from), width_for(till))}
  end

  def percentage(width, left, _right) when width == left, do: 0
  def percentage(width, _left, right) when width == right, do: 100

  def percentage(width, left, right) when width > left and width < right and left < right do
    ((width - left) * 100 / (right - left))
    |> Decimal.from_float()
    |> Decimal.round(0, :up)
    |> Decimal.to_integer()
  end

  def value(current_bp, base_value, break_values) do
    break_values
    |> Enum.reduce(
      base_value,
      fn {break_value, value}, acc ->
        validate(current_bp, break_value, value, acc)
      end
    )
  end

  def validate({break_value, percentage}, curent_break_value, %{} = values, acc) do
    if break_value == curent_break_value do
      value_for_percentage(values, percentage, acc)
    else
      if down_from?(break_value, curent_break_value) do
        max_value(values)
      else
        acc
      end
    end
  end

  def validate({break_value, _percentage}, curent_break_value, value, acc) do
    if down_from?(break_value, curent_break_value) do
      value
    else
      acc
    end
  end

  def value_for_percentage([] = _values, _percentage, acc), do: acc

  def value_for_percentage(values, percentage, acc) do
    values
    |> Enum.reduce(acc, fn {key, value}, acc ->
      if key <= percentage do
        value
      else
        acc
      end
    end)
  end

  def max_value(values) do
    max =
      values
      |> Map.keys()
      |> Enum.max()

    values
    |> Map.get(max)
  end

  def up_from?(current, marker) do
    compare(marker, current) >= 0
  end

  def down_from?(current, marker) do
    compare(marker, current) <= 0
  end

  def compare(left, right) do
    index_of(left) - index_of(right)
  end

  def index_of(break) do
    Enum.find_index(break_values(), &(&1 == break))
  end

  def remove_first([]), do: []

  def remove_first(enum) do
    enum |> tl()
  end

  defp break_values() do
    Keyword.keys(@breakpoints)
  end

  def zip_shift_left(break_values) do
    break_values1 = break_values
    break_values2 = break_values |> remove_first()
    Enum.zip(break_values1, break_values2)
  end
end
