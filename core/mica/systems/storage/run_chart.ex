defmodule Systems.Storage.RunChart do
  @moduledoc """
  Geometry for charts of the trials of a run, with a band per Prompt. A dot
  chart has one dot per trial in donation order, on one y-axis through 0.
  Within a band a thin line connects the dots (monotone, so it never overshoots
  a measured value) and, from 5 trials up, a trend line shows the mean of up to
  5 neighbouring trials. Lines stop at each Prompt boundary. A share chart has
  one bar per band: the share of its trials with 1.
  """

  @width 1000
  @height 220
  @left 56
  @right 16
  @top 36
  @bottom 24
  # Average width of a 12px character of the chart font, with the label's 8px inset and 2px air.
  @char_width 6.2
  @label_padding 10
  @trend_window 5

  def width, do: @width

  @doc "Numeric fields of the records, in order of first appearance."
  def columns(prompts) do
    prompts
    |> records()
    |> Enum.flat_map(fn fields -> for {key, value} <- fields, is_number(value), do: key end)
    |> Enum.uniq()
  end

  @doc """
  The charts that mean something without knowing the Tool, in this order:

  1. a measurement, a field ending in `_ms` that varies within a Prompt, as dots
     per trial (`rt_ms` first; `time_limit_ms`, a setting per Prompt, stays out);
  2. a field of only 0 and 1, with both, as the share of 1 per Prompt (`correct`).

  Other fields (codes, positions, clock times, indices) look like numbers but are
  no measurement; `all?: true` adds every one that varies, as dots.
  """
  def charts(prompts, opts \\ []) do
    varying = prompts |> columns() |> Enum.filter(&varies?(prompts, &1))

    measurements =
      varying |> Enum.filter(&measurement?(prompts, &1)) |> Enum.sort_by(&(&1 != "rt_ms"))

    shares = Enum.filter(varying -- measurements, &binary?(prompts, &1))
    others = if Keyword.get(opts, :all?, false), do: varying -- (measurements ++ shares), else: []

    (Enum.map(measurements, &{:dots, &1}) ++
       Enum.map(shares, &{:share, &1}) ++ Enum.map(others, &{:dots, &1}))
    |> Enum.with_index()
    |> Enum.map(fn
      {{:dots, column}, index} -> build(prompts, column, labels?: index == 0)
      {{:share, column}, index} -> share(prompts, column, labels?: index == 0)
    end)
  end

  @doc "How many fields `charts/1` leaves out that `all?: true` shows."
  def hidden_count(prompts),
    do: Enum.count(charts(prompts, all?: true)) - Enum.count(charts(prompts))

  defp varies?(prompts, column) do
    prompts |> values(column) |> Enum.uniq() |> Enum.count() > 1
  end

  defp measurement?(prompts, column) do
    String.ends_with?(column, "_ms") and
      Enum.any?(prompts, fn prompt -> varies?([prompt], column) end)
  end

  defp binary?(prompts, column) do
    prompts |> values(column) |> Enum.all?(&(&1 == 0 or &1 == 1))
  end

  def build(prompts, column, opts \\ []) do
    values = values(prompts, column)
    ticks = ticks(Enum.min(values, fn -> 0 end), Enum.max(values, fn -> 0 end))
    scale = fn value -> y(value, List.first(ticks), List.last(ticks)) end

    chart(prompts, column, :dots, opts,
      ticks: Enum.map(ticks, fn tick -> %{y: scale.(tick), label: format(tick)} end),
      band: fn label, records, offset, step ->
        band(label, records, column, offset, step, scale)
      end
    )
  end

  @doc "The share of trials with 1 per Prompt, as a bar per band on a 0–100% axis."
  def share(prompts, column, opts \\ []) do
    scale = fn value -> y(value, 0, 1) end

    chart(prompts, column, :share, opts,
      ticks: for(tick <- [0, 0.25, 0.5, 0.75, 1], do: %{y: scale.(tick), label: percent(tick)}),
      band: fn label, records, offset, step ->
        share_band(label, records, column, offset, step, scale)
      end
    )
  end

  defp chart(prompts, column, type, opts, ticks: ticks, band: band_fun) do
    count = prompts |> records() |> Enum.count()
    step = (@width - @left - @right) / max(count, 1)

    {bands, _offset} =
      prompts
      |> short_labels()
      |> Enum.map_reduce(0, fn %{label: label, records: records}, offset ->
        x = @left + offset * step
        width = Enum.count(records) * step

        band =
          %{x: x, width: width, label: label, short_label: fit(label, width)}
          |> Map.merge(band_fun.(label, records, offset, step))

        {band, offset + Enum.count(records)}
      end)

    %{
      type: type,
      column: column,
      width: @width,
      height: @height,
      plot: %{left: @left, right: @width - @right, top: @top, bottom: @height - @bottom},
      labels?: Keyword.get(opts, :labels?, true),
      bands:
        bands
        |> Enum.with_index()
        |> Enum.map(fn {band, index} -> Map.put(band, :shaded?, rem(index, 2) == 1) end),
      y_ticks: ticks,
      count: count
    }
  end

  # All Prompts of one flow: "motor" instead of "symbols / motor", so a narrow band keeps its label.
  defp short_labels(prompts) do
    parts = Enum.map(prompts, fn %{label: label} -> String.split(label, " / ", parts: 2) end)

    case Enum.uniq_by(parts, &hd/1) do
      [[_flow, _prompt]] ->
        Enum.zip_with(prompts, parts, fn prompt, [_flow, name] -> %{prompt | label: name} end)

      _ ->
        prompts
    end
  end

  defp band(label, records, column, offset, step, scale) do
    measured =
      records
      |> Enum.with_index()
      |> Enum.flat_map(fn {fields, index} ->
        case List.keyfind(fields, column, 0) do
          {_key, value} when is_number(value) ->
            [{@left + (offset + index + 0.5) * step, value, index}]

          _ ->
            []
        end
      end)

    %{
      points:
        Enum.map(measured, fn {px, value, index} ->
          %{x: px, y: scale.(value), tooltip: "#{label} · trial #{index + 1}: #{format(value)}"}
        end),
      connection: measured |> Enum.map(fn {px, value, _} -> {px, scale.(value)} end) |> path(),
      trend: trend(measured, scale)
    }
  end

  defp share_band(label, records, column, offset, step, scale) do
    case values([%{records: records}], column) do
      [] -> %{bar: nil}
      values -> %{bar: bar(label, values, {offset, Enum.count(records)}, step, scale)}
    end
  end

  defp bar(label, values, {offset, trials}, step, scale) do
    ones = Enum.count(values, &(&1 == 1))
    share = ones / Enum.count(values)
    width = min(trials * step * 0.6, 40)
    x = @left + (offset + trials / 2) * step - width / 2
    top = scale.(share)
    bottom = scale.(0)

    %{
      x: x + width / 2,
      y: top,
      path: rounded_top(x, top, width, bottom),
      label: percent(share),
      tooltip: "#{label}: #{ones} of #{Enum.count(values)} (#{percent(share)})"
    }
  end

  # A bar anchored to the baseline with its data end rounded (4px).
  defp rounded_top(_x, top, _width, bottom) when bottom - top < 0.5, do: nil

  defp rounded_top(x, top, width, bottom) do
    radius = Enum.min([4, width / 2, bottom - top])

    "M#{r(x)},#{r(bottom)} V#{r(top + radius)} Q#{r(x)},#{r(top)} #{r(x + radius)},#{r(top)} " <>
      "H#{r(x + width - radius)} Q#{r(x + width)},#{r(top)} #{r(x + width)},#{r(top + radius)} " <>
      "V#{r(bottom)} Z"
  end

  defp percent(share), do: "#{round(share * 100)}%"

  @doc "The label as it fits in a band: whole, shortened with …, or nil when not even 3 characters fit."
  def fit(label, width) do
    room = floor((width - @label_padding) / @char_width)

    cond do
      String.length(label) <= room -> label
      room >= 3 -> String.slice(label, 0, room - 1) <> "…"
      true -> nil
    end
  end

  defp trend(measured, _scale) when length(measured) < @trend_window, do: nil

  defp trend(measured, scale) do
    values = Enum.map(measured, fn {_x, value, _index} -> value end)
    half = div(@trend_window, 2)
    last = Enum.count(values) - 1

    measured
    |> Enum.with_index()
    |> Enum.map(fn {{px, _value, _index}, i} ->
      window = Enum.slice(values, max(i - half, 0)..min(i + half, last))
      {px, scale.(Enum.sum(window) / Enum.count(window))}
    end)
    |> path()
  end

  @doc "A monotone cubic path (Fritsch–Carlson) through the points: no overshoot."
  def path(points) when length(points) < 2, do: nil

  def path([{x0, y0} | _] = points) do
    tangents = tangents(points)

    segments =
      points
      |> Enum.zip(tangents)
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.map(fn [{{xa, ya}, ta}, {{xb, yb}, tb}] ->
        third = (xb - xa) / 3

        "C#{r(xa + third)},#{r(ya + ta * third)} #{r(xb - third)},#{r(yb - tb * third)} #{r(xb)},#{r(yb)}"
      end)

    Enum.join(["M#{r(x0)},#{r(y0)}" | segments], " ")
  end

  defp tangents(points) do
    slopes =
      points
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.map(fn [{xa, ya}, {xb, yb}] -> (yb - ya) / (xb - xa) end)

    initial =
      [List.first(slopes)] ++
        (slopes
         |> Enum.chunk_every(2, 1, :discard)
         |> Enum.map(fn [a, b] -> if a * b <= 0, do: 0.0, else: (a + b) / 2 end)) ++
        [List.last(slopes)]

    limit(initial, slopes)
  end

  # Fritsch–Carlson: scale the tangents of a segment down where they would overshoot.
  defp limit(tangents, slopes) do
    slopes
    |> Enum.with_index()
    |> Enum.reduce(tangents, fn {slope, i}, acc -> limit_segment(acc, slope, i) end)
  end

  defp limit_segment(tangents, slope, i) when slope == 0 do
    tangents |> List.replace_at(i, 0.0) |> List.replace_at(i + 1, 0.0)
  end

  defp limit_segment(tangents, slope, i) do
    a = Enum.at(tangents, i) / slope
    b = Enum.at(tangents, i + 1) / slope
    s = a * a + b * b

    if s > 9 do
      tau = 3 / :math.sqrt(s)
      tangents |> List.replace_at(i, tau * a * slope) |> List.replace_at(i + 1, tau * b * slope)
    else
      tangents
    end
  end

  defp records(prompts), do: Enum.flat_map(prompts, fn %{records: records} -> records end)

  defp values(prompts, column) do
    prompts
    |> records()
    |> Enum.flat_map(fn fields ->
      case List.keyfind(fields, column, 0) do
        {_key, value} when is_number(value) -> [value]
        _ -> []
      end
    end)
  end

  @doc """
  Clean ticks from a round number at or below the minimum to one at or above the
  maximum, always through 0: negative values (an angle, a position) stay on the plot.
  """
  def ticks(max_value), do: ticks(0, max_value)

  def ticks(min_value, max_value) do
    low = min(min_value, 0)
    high = max(max_value, 0)

    if high == low do
      [0, 1]
    else
      step = nice_step((high - low) / 4)
      bottom = Float.floor(low / step) * step
      top = Float.ceil(high / step) * step
      Enum.map(0..round((top - bottom) / step), &(bottom + &1 * step))
    end
  end

  defp nice_step(raw) do
    magnitude = :math.pow(10, Float.floor(:math.log10(raw)))
    Enum.find([1, 2, 5, 10], &(&1 * magnitude >= raw)) * magnitude
  end

  defp y(value, low, high),
    do: @height - @bottom - (value - low) / (high - low) * (@height - @bottom - @top)

  defp r(value), do: :erlang.float_to_binary(value / 1, decimals: 1)

  defp format(value) when is_float(value) do
    if value == Float.round(value),
      do: compact(round(value)),
      else: :erlang.float_to_binary(value, decimals: 2)
  end

  defp format(value), do: compact(value)

  defp compact(value) when is_integer(value) and value >= 1000 do
    if rem(value, 1000) == 0,
      do: "#{div(value, 1000)}K",
      else: "#{Float.round(value / 1000, 1)}K"
  end

  defp compact(value), do: to_string(value)
end
