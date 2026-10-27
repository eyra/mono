defmodule Core.ObanConfigTest do
  use ExUnit.Case, async: true

  alias Core.ObanConfig

  @node_queue :"storage_delivery_local_#{Node.self()}"

  test "Mica's queues are default and this node's storage delivery queue" do
    assert ObanConfig.queues() == [{@node_queue, 1}, default: 5]

    assert ObanConfig.queues(:"core@web-01") == [
             {:"storage_delivery_local_core@web-01", 1},
             default: 5
           ]
  end

  test "adds Mica's and the declared queues to the config" do
    assert ObanConfig.config([repo: Core.Repo], ris_import: 1) == [
             queues: [{@node_queue, 1}, default: 5, ris_import: 1],
             repo: Core.Repo
           ]
  end

  test "a queue listed in the config keeps its limit" do
    assert ObanConfig.config([queues: [ris_import: 3]], ris_import: 1)[:queues] == [
             {@node_queue, 1},
             default: 5,
             ris_import: 3
           ]
  end

  test "a system can't declare one of Mica's queues" do
    assert_raise ArgumentError, "Oban queue :default is Mica's; a system can't declare it", fn ->
      ObanConfig.config([], default: 1)
    end
  end

  test "Oban accepts the queues of the SaaS" do
    config = ObanConfig.config([repo: Core.Repo], Core.SaaS.oban_queues())
    assert :ok = Oban.Config.validate(config)
  end

  test "queues: false keeps every queue off" do
    assert ObanConfig.config([queues: false], ris_import: 1) == [queues: false]
  end
end
