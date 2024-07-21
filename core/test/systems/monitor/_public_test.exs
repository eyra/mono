defmodule Systems.Monitor.PublicTest do
  use Core.DataCase

  import Ecto.Query

  alias Core.Factories
  alias Core.Repo
  alias Systems.Monitor

  describe "Monitor events" do
    test "log_performance_event/2 single log" do
      identifier = ["assignment=1", "topic=declined", "user=1"]
      Monitor.Public.log(identifier)

      assert [
               %Systems.Monitor.EventModel{
                 identifier: ^identifier,
                 value: 1
               }
             ] = from(Monitor.EventModel) |> Repo.all()
    end

    test "log_performance_event/2 multiple logs" do
      Monitor.Public.log(["assignment=1", "topic=declined", "user=1"])
      Monitor.Public.log(["assignment=1", "topic=declined", "user=2"])
      Monitor.Public.log(["assignment=1", "topic=declined", "user=1"])

      assert [
               %Systems.Monitor.EventModel{
                 identifier: ["assignment=1", "topic=declined", "user=1"]
               },
               %Systems.Monitor.EventModel{
                 identifier: ["assignment=1", "topic=declined", "user=2"]
               },
               %Systems.Monitor.EventModel{
                 identifier: ["assignment=1", "topic=declined", "user=1"]
               }
             ] = from(Monitor.EventModel) |> Repo.all()
    end

    test "clear/1 multiple logs" do
      Monitor.Public.log(["assignment=1", "topic=declined", "user=1"])
      Monitor.Public.log(["assignment=1", "topic=declined", "user=2"])
      Monitor.Public.log(["assignment=1", "topic=declined", "user=1"])

      Monitor.Public.clear(["assignment=1", "topic=declined", "user=1"])

      assert [
               %Systems.Monitor.EventModel{
                 identifier: ["assignment=1", "topic=declined", "user=2"]
               }
             ] = from(Monitor.EventModel) |> Repo.all()
    end

    test "reset/1 multiple logs" do
      Monitor.Public.log(["storage=1", "topic=bytes"], value: 10)
      Monitor.Public.log(["storage=1", "topic=bytes"], value: 200)
      Monitor.Public.log(["storage=1", "topic=bytes"], value: 3456)

      Monitor.Public.reset(["storage=1", "topic=bytes"])

      assert Monitor.Public.count(["storage=1", "topic=bytes"]) == 4
      assert Monitor.Public.sum(["storage=1", "topic=bytes"]) == 0

      assert [
               %Systems.Monitor.EventModel{identifier: ["storage=1", "topic=bytes"], value: 10},
               %Systems.Monitor.EventModel{identifier: ["storage=1", "topic=bytes"], value: 200},
               %Systems.Monitor.EventModel{identifier: ["storage=1", "topic=bytes"], value: 3456},
               %Systems.Monitor.EventModel{
                 identifier: ["storage=1", "topic=bytes", "action=reset"],
                 value: -3666
               }
             ] = from(Monitor.EventModel) |> Repo.all()
    end
  end

  describe "Monitor metrics" do
    setup do
      Factories.insert!(:monitor_event, %{
        identifier: ["assignment=1", "topic=declined", "user=1"],
        value: 10
      })

      Factories.insert!(:monitor_event, %{
        identifier: ["assignment=1", "topic=declined", "user=2"],
        value: 10
      })

      Factories.insert!(:monitor_event, %{
        identifier: ["assignment=1", "topic=declined", "user=1"],
        value: 10
      })

      :ok
    end

    test "count/1" do
      assert 3 = Monitor.Public.count(["assignment=1"])
      assert 3 = Monitor.Public.count(["assignment=1", "topic=declined"])
      assert 2 = Monitor.Public.count(["assignment=1", "topic=declined", "user=1"])
      assert 1 = Monitor.Public.count(["assignment=1", "topic=declined", "user=2"])
      assert 0 = Monitor.Public.count(["assignment=1", "topic=declined", "user=3"])
    end

    test "unique/1" do
      assert 2 = Monitor.Public.unique(["assignment=1"])
      assert 2 = Monitor.Public.unique(["assignment=1", "topic=declined"])
      assert 1 = Monitor.Public.unique(["assignment=1", "topic=declined", "user=1"])
      assert 1 = Monitor.Public.unique(["assignment=1", "topic=declined", "user=2"])
      assert 0 = Monitor.Public.unique(["assignment=1", "topic=declined", "user=3"])
    end

    test "sum/1" do
      assert 30 = Monitor.Public.sum(["assignment=1"])
      assert 30 = Monitor.Public.sum(["assignment=1", "topic=declined"])
      assert 20 = Monitor.Public.sum(["assignment=1", "topic=declined", "user=1"])
      assert 10 = Monitor.Public.sum(["assignment=1", "topic=declined", "user=2"])
      assert 0 = Monitor.Public.sum(["assignment=1", "topic=declined", "user=3"])
    end
  end
end
