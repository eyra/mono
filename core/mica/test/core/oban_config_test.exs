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

  describe "put_plugins/3" do
    @crons [
      first_cron: {"* * * * *", FirstWorker},
      second_cron: {"0 * * * *", SecondWorker, queue: :other}
    ]

    test "puts the enabled plugins first, then one Cron plugin with the enabled crons in declared order" do
      oban_plugins = [enabled: ["second_cron", "lifeline", "first_cron", "pruner"]]

      assert ObanConfig.put_plugins([repo: Core.Repo], @crons, oban_plugins)[:plugins] == [
               {Oban.Plugins.Pruner, max_age: 3600},
               {Oban.Plugins.Lifeline, rescue_after: 3_600_000},
               {Oban.Plugins.Cron,
                crontab: [
                  {"* * * * *", FirstWorker},
                  {"0 * * * *", SecondWorker, queue: :other}
                ]}
             ]
    end

    test "adds no Cron plugin when no cron is enabled" do
      assert ObanConfig.put_plugins([], @crons, enabled: ["pruner"]) == [
               plugins: [{Oban.Plugins.Pruner, max_age: 3600}]
             ]
    end

    test "enables nothing by default" do
      assert ObanConfig.put_plugins([], @crons, []) == [plugins: []]
    end

    test ":all enables every plugin and cron" do
      assert [
               {Oban.Plugins.Pruner, _},
               {Oban.Plugins.Lifeline, _},
               {Oban.Plugins.Cron, crontab: [_, _]}
             ] = ObanConfig.put_plugins([], @crons, enabled: :all)[:plugins]
    end

    test "a schedule override replaces the schedule of the cron it names" do
      oban_plugins = [enabled: :all, schedule_overrides: [second_cron: "*/10 * * * *"]]

      assert {Oban.Plugins.Cron,
              crontab: [
                {"* * * * *", FirstWorker},
                {"*/10 * * * *", SecondWorker, queue: :other}
              ]} = List.last(ObanConfig.put_plugins([], @crons, oban_plugins)[:plugins])
    end

    test "keeps the plugins the config lists" do
      config = [plugins: [{Oban.Plugins.Reindexer, []}]]

      assert ObanConfig.put_plugins(config, @crons, enabled: ["pruner"])[:plugins] == [
               {Oban.Plugins.Reindexer, []},
               {Oban.Plugins.Pruner, max_age: 3600}
             ]
    end

    test "plugins: false keeps every plugin off" do
      assert ObanConfig.put_plugins([plugins: false], @crons, enabled: :all) == [plugins: false]
    end

    test "a system can't declare a cron with the name of one of Mica's plugins" do
      assert_raise ArgumentError,
                   "Oban plugin :pruner is Mica's; a system can't declare it",
                   fn ->
                     ObanConfig.put_plugins([], [pruner: {"* * * * *", FirstWorker}],
                       enabled: :all
                     )
                   end
    end
  end

  describe "unknown_plugins/2" do
    test "returns the enabled names that are neither Mica's plugins nor a cron, once" do
      oban_plugins = [enabled: ["pruner", "typo", "first_cron", "typo"]]

      assert ObanConfig.unknown_plugins([first_cron: {"* * * * *", FirstWorker}], oban_plugins) ==
               ["typo"]
    end

    test "is empty for :all and when nothing is enabled" do
      assert ObanConfig.unknown_plugins([], enabled: :all) == []
      assert ObanConfig.unknown_plugins([], []) == []
    end
  end

  test "Oban accepts every plugin and cron of the SaaS" do
    config = ObanConfig.put_plugins([repo: Core.Repo], Core.SaaS.oban_crons(), enabled: :all)
    assert :ok = Oban.Config.validate(config)
  end
end
