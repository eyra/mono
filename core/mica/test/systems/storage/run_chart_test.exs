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

    assert prompts |> RunChart.charts(all?: true) |> Enum.map(& &1.column) == [
             "rt_ms",
             "trial_index"
           ]
  end

  describe "charts that mean something" do
    @run [
      %{
        label: "symbols / practice",
        records: [
          [
            {"trial_index", 1},
            {"option_1", 238},
            {"time_limit_ms", 8000},
            {"correct", 1},
            {"rt_ms", 900}
          ],
          [
            {"trial_index", 2},
            {"option_1", 504},
            {"time_limit_ms", 8000},
            {"correct", 0},
            {"rt_ms", 700}
          ]
        ]
      },
      %{
        label: "symbols / test",
        records: [
          [
            {"trial_index", 1},
            {"option_1", 17},
            {"time_limit_ms", 5000},
            {"correct", 1},
            {"rt_ms", 650}
          ],
          [
            {"trial_index", 2},
            {"option_1", 33},
            {"time_limit_ms", 5000},
            {"correct", 1},
            {"rt_ms", 640}
          ]
        ]
      }
    ]

    test "shows a measurement and a 0/1 field" do
      assert @run |> RunChart.charts() |> Enum.map(&{&1.type, &1.column}) == [
               dots: "rt_ms",
               share: "correct"
             ]
    end

    test "leaves out a field ending in _ms that is one setting per Prompt" do
      refute "time_limit_ms" in (@run |> RunChart.charts() |> Enum.map(& &1.column))
    end

    test "adds the other fields that vary when asked for all fields" do
      assert @run |> RunChart.charts(all?: true) |> Enum.map(& &1.column) == [
               "rt_ms",
               "correct",
               "trial_index",
               "option_1",
               "time_limit_ms"
             ]
    end

    test "counts the fields it leaves out" do
      assert RunChart.hidden_count(@run) == 3
    end

    test "shows the share of 1 per Prompt" do
      %{bands: bands} = RunChart.share(@run, "correct")

      assert Enum.map(bands, & &1.bar.label) == ["50%", "100%"]
    end

    test "draws no bar for a Prompt where every trial has 0" do
      prompts = [%{label: "p", records: [[{"correct", 0}], [{"correct", 0}]]}]

      assert %{bands: [%{bar: %{label: "0%", path: nil}}]} = RunChart.share(prompts, "correct")
    end

    test "keeps a bar inside the plot" do
      %{bands: bands, plot: %{top: top, bottom: bottom}} = RunChart.share(@run, "correct")

      assert Enum.all?(bands, fn %{bar: %{y: y}} -> y >= top and y <= bottom end)
    end
  end

  test "draws one dot per trial with a number" do
    %{bands: bands, count: 3} = RunChart.build(@prompts, "rt_ms")

    assert bands |> Enum.flat_map(& &1.points) |> Enum.count() == 2
  end

  test "labels each band with its Prompt when all Prompts share a flow" do
    assert %{bands: [%{label: "practice1"}, %{label: "test"}]} =
             RunChart.build(@prompts, "rt_ms")
  end

  test "fits a label in a narrow band" do
    assert RunChart.fit("practice1", 68.0) == "practice1"
  end

  test "shortens a label that does not fit" do
    assert RunChart.fit("switch-test", 50.0) == "switc…"
  end

  test "keeps the flow in the labels of Prompts from different flows" do
    prompts = [
      %{label: "symbols / test", records: [[{"rt_ms", 1}]]},
      %{label: "cogflex / test", records: [[{"rt_ms", 2}]]}
    ]

    assert %{bands: [%{label: "symbols / test"}, %{label: "cogflex / test"}]} =
             RunChart.build(prompts, "rt_ms")
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
