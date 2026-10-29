defmodule Systems.Storage.RunChart do
  @moduledoc """
  Geometry for a dot chart of one numeric field over the trials of a run: one
  dot per trial in donation order, on one y-axis from 0, with a labelled band
  per Prompt. A single series in one color; the bands, not colors, tell the
  Prompts apart.
  """

  @width 1000
  @height 320
  @left 56
  @right 16
  @top 36
  @bottom 28
  @char_width 7

  @doc "Numeric fields of the records, in order of first appearance."
  def columns(prompts) do
    prompts
    |> Enum.flat_map(fn %{records: records} -> records end)
    |> Enum.flat_map(fn fields -> for {key, value} <- fields, number?(value), do: key end)
    |> Enum.uniq()
  end

  @doc "The requested column when the records have it, else `rt_ms`, else the first numeric one."
  def column(prompts, requested) do
    columns = columns(prompts)

    cond do
      requested in columns -> requested
      "rt_ms" in columns -> "rt_ms"
      true -> List.first(columns)
    end
  end

  def build(prompts, column) do
    count = prompts |> Enum.map(fn %{records: records} -> Enum.count(records) end) |> Enum.sum()
    step = (@width - @left - @right) / max(count, 1)
    max_value = max_value(prompts, column)
    ticks = ticks(max_value)
    top_tick = List.last(ticks)

    {bands, points, _offset} =
      Enum.reduce(prompts, {[], [], 0}, fn %{label: label, records: records},
                                           {bands, points, offset} ->
        band = band(label, offset, Enum.count(records), step, Enum.count(bands))
        new_points = points(label, records, column, offset, step, top_tick)
        {[band | bands], points ++ new_points, offset + Enum.count(records)}
      end)

    %{
      width: @width,
      height: @height,
      plot: %{left: @left, right: @width - @right, top: @top, bottom: @height - @bottom},
      bands: Enum.reverse(bands),
      points: points,
      y_ticks: Enum.map(ticks, fn tick -> %{y: y(tick, top_tick), label: format(tick)} end),
      count: count
    }
  end

  defp band(label, offset, count, step, index) do
    x = @left + offset * step
    width = count * step

    %{
      x: x,
      width: width,
      label: label,
      show_label?: String.length(label) * @char_width + 12 <= width,
      shaded?: rem(index, 2) == 1
    }
  end

  defp points(label, records, column, offset, step, top_tick) do
    records
    |> Enum.with_index()
    |> Enum.flat_map(fn {fields, index} ->
      case List.keyfind(fields, column, 0) do
        {_key, value} when is_number(value) ->
          [
            %{
              x: @left + (offset + index + 0.5) * step,
              y: y(value, top_tick),
              tooltip: "#{label} · trial #{index + 1}: #{format(value)}"
            }
          ]

        _ ->
          []
      end
    end)
  end

  defp max_value(prompts, column) do
    prompts
    |> Enum.flat_map(fn %{records: records} -> records end)
    |> Enum.flat_map(fn fields ->
      case List.keyfind(fields, column, 0) do
        {_key, value} when is_number(value) -> [value]
        _ -> []
      end
    end)
    |> Enum.max(fn -> 0 end)
  end

  @doc "Clean ticks from 0 up to a round number at or above the maximum."
  def ticks(max_value) when max_value <= 0, do: [0, 1]

  def ticks(max_value) do
    step = nice_step(max_value / 4)
    top = Float.ceil(max_value / step) * step
    count = round(top / step)
    Enum.map(0..count, &(&1 * step))
  end

  defp nice_step(raw) do
    magnitude = :math.pow(10, Float.floor(:math.log10(raw)))

    Enum.find([1, 2, 5, 10], &(&1 * magnitude >= raw)) * magnitude
  end

  defp y(value, top_tick), do: @height - @bottom - value / top_tick * (@height - @bottom - @top)

  defp number?(value), do: is_number(value)

  defp format(value) when is_float(value) do
    if value == Float.round(value),
      do: compact(round(value)),
      else: :erlang.float_to_binary(value, decimals: 2)
  end

  defp format(value), do: compact(value)

  defp compact(value) when is_integer(value) and value >= 1000 do
    if rem(value, 1000) == 0, do: "#{div(value, 1000)}K", else: "#{Float.round(value / 1000, 1)}K"
  end

  defp compact(value), do: to_string(value)
end
