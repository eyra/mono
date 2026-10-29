defmodule Systems.Storage.DonationViewTest do
  use ExUnit.Case, async: true

  alias Systems.Storage.DonationView

  defp blocks(json) do
    {:ok, donation} = DonationView.decode(json)
    DonationView.blocks(donation)
  end

  test "shows a flat record as a table with one row, in field order" do
    json = ~s({"session_id":"r1","test_name":"Symbol Search","display_width":1792})

    assert {:table, ["session_id", "test_name", "display_width"], [["r1", "Symbol Search", 1792]]} =
             blocks(json)
  end

  test "shows a Prompt result as its envelope and a table of its responses" do
    json =
      ~s({"runId":"r1","promptId":"practice1","implementation":"cogflex-trials",
      "responses":[{"trial_index":1,"rule":"tilt","rt_ms":2057},{"trial_index":2,"rule":"tilt","rt_ms":980}]})

    assert {:tree, {:table, ["runId", "promptId", "implementation"], [_]},
            [
              {"responses",
               {:table, ["trial_index", "rule", "rt_ms"], [[1, "tilt", 2057], [2, "tilt", 980]]}}
            ]} = blocks(json)
  end

  test "shows a trial as its envelope and a one-row table of its response" do
    json = ~s({"runId":"r1","index":0,"response":{"item_id":"P1_001","correct":1}})

    assert {:tree, {:table, ["runId", "index"], _},
            [{"response", {:table, ["item_id", "correct"], [["P1_001", 1]]}}]} = blocks(json)
  end

  test "keeps a list of scalars in a record as one cell" do
    json = ~s({"item_id":"Q1","response_options":["Lotte","Sanne"]})

    assert {:table, ["item_id", "response_options"], [["Q1", ["Lotte", "Sanne"]]]} = blocks(json)
  end

  test "uses the union of the keys of all records as columns" do
    json = ~s([{"a":1},{"a":2,"b":3}])

    assert {:table, ["a", "b"], [[1, nil], [2, 3]]} = blocks(json)
  end

  test "falls back to a tree for nested values" do
    json = ~s({"data":{"points":[[1,2],[3]]}})

    assert {:tree, nil,
            [
              {"data",
               {:tree, nil,
                [
                  {"points",
                   {:list, [{:list, [{:value, 1}, {:value, 2}]}, {:list, [{:value, 3}]}]}}
                ]}}
            ]} = blocks(json)
  end
end
