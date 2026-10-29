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

  test "lists the numeric columns in order of first appearance" do
    assert RunChart.columns(@prompts) == ["trial_index", "rt_ms"]
  end

  test "picks rt_ms when no column is requested" do
    assert RunChart.column(@prompts, nil) == "rt_ms"
  end

  test "keeps a requested column the records have" do
    assert RunChart.column(@prompts, "trial_index") == "trial_index"
  end

  test "ignores a requested column the records do not have" do
    assert RunChart.column(@prompts, "phase") == "rt_ms"
  end

  test "draws one dot per trial with a number" do
    assert %{points: [_, _], count: 3} = RunChart.build(@prompts, "rt_ms")
  end

  test "draws a band per Prompt" do
    assert %{bands: [%{label: "symbols / practice1"}, %{label: "symbols / test"}]} =
             RunChart.build(@prompts, "rt_ms")
  end
end
