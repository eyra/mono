defmodule Systems.Storage.RunChartTest do
  use ExUnit.Case, async: true

  alias Systems.Storage.RunChart

  @prompts [
    %{
      label: "symbols / practice1",
      records: [[{"trial_index", 1}, {"rt_ms", 1467}, {"phase", "practice1"}]]
    },
    %{
      label: "symbols / test",
      records: [[{"trial_index", 1}, {"rt_ms", 980}], [{"trial_index", 2}, {"rt_ms", nil}]]
    }
  ]

  test "rounds the top tick up to a clean number" do
    assert RunChart.ticks(1467) == [0.0, 500.0, 1000.0, 1500.0]
  end

  test "extends the ticks below 0 for negative values" do
    assert RunChart.ticks(-0.8, 0.5) == [-1.0, -0.5, 0.0, 0.5]
  end

  test "keeps every dot of negative values inside the plot" do
    prompts = [%{label: "p", records: [[{"angle", -55}], [{"angle", 50}], [{"angle", -20}]]}]

    %{bands: [%{points: points}], plot: %{top: top, bottom: bottom}} =
      RunChart.build(prompts, "angle")

    assert Enum.all?(points, fn %{y: y} -> y >= top and y <= bottom end)
  end

  test "lists the numeric columns in order of first appearance" do
    assert RunChart.columns(@prompts) == ["trial_index", "rt_ms"]
  end

  test "puts rt_ms first and leaves out a field with one value" do
    prompts = [
      %{
        label: "p",
        records: [
          [{"same", 1}, {"trial_index", 1}, {"rt_ms", 900}],
          [{"same", 1}, {"trial_index", 2}, {"rt_ms", 700}]
        ]
      }
    ]

    assert prompts |> RunChart.charts() |> Enum.map(& &1.column) == ["rt_ms", "trial_index"]
  end

  test "draws one dot per trial with a number" do
    %{bands: bands, count: 3} = RunChart.build(@prompts, "rt_ms")

    assert bands |> Enum.flat_map(& &1.points) |> Enum.count() == 2
  end

  test "draws a band per Prompt" do
    assert %{bands: [%{label: "symbols / practice1"}, %{label: "symbols / test"}]} =
             RunChart.build(@prompts, "rt_ms")
  end

  test "draws no trend in a Prompt with fewer than 5 trials" do
    assert %{bands: [%{trend: nil} | _]} = RunChart.build(@prompts, "rt_ms")
  end

  test "draws a trend in a Prompt with 5 trials" do
    records = for rt <- [500, 900, 700, 800, 600], do: [{"rt_ms", rt}]

    assert %{bands: [%{trend: "M" <> _}]} =
             RunChart.build([%{label: "p", records: records}], "rt_ms")
  end

  test "connects the dots without overshooting a measured value" do
    path = RunChart.path([{0.0, 0.0}, {10.0, 100.0}, {20.0, 100.0}, {30.0, 0.0}])

    ys =
      Regex.scan(~r/-?[0-9.]+,(-?[0-9.]+)/, path, capture: :all_but_first)
      |> Enum.map(fn [y] -> String.to_float(y) end)

    assert Enum.all?(ys, &(&1 >= 0.0 and &1 <= 100.0))
  end
end
