defmodule Systems.Monitor.PublicTest do
  use Mica.DataCase

  import Ecto.Query

  alias Ecto.Multi
  alias Mica.Factories
  alias Mica.Repo
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

    test "reset/1 with values exceeding 32-bit integer range" do
      # Simulate ~4.7GB of file storage (the actual bug scenario)
      # 32-bit signed integer max is 2,147,483,647
      large_value = 4_776_318_715

      Monitor.Public.log(["storage=2", "topic=bytes"], value: large_value)

      assert Monitor.Public.sum(["storage=2", "topic=bytes"]) == large_value

      Monitor.Public.reset(["storage=2", "topic=bytes"])

      assert Monitor.Public.count(["storage=2", "topic=bytes"]) == 2
      assert Monitor.Public.sum(["storage=2", "topic=bytes"]) == 0

      assert [
               %Systems.Monitor.EventModel{
                 identifier: ["storage=2", "topic=bytes"],
                 value: ^large_value
               },
               %Systems.Monitor.EventModel{
                 identifier: ["storage=2", "topic=bytes", "action=reset"],
                 value: -4_776_318_715
               }
             ] = from(Monitor.EventModel) |> Repo.all()
    end
  end

  describe "Monitor telemetry" do
    setup do
      handler_id = "monitor-telemetry-test-#{inspect(self())}"

      :telemetry.attach(
        handler_id,
        [:monitor, :event, :count],
        &__MODULE__.forward_telemetry/4,
        self()
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)
    end

    test "log/2 emits the value with the identifier's keys except user" do
      Monitor.Public.log(["assignment=1", "topic=declined", "user=1"])

      assert_received {:monitor_telemetry, %{count: 1},
                       %{"assignment" => "1", "topic" => "declined"} = metadata}

      refute Map.has_key?(metadata, "user")
    end

    test "multi_log/3 emits the value once its transaction commits" do
      multi = Monitor.Public.multi_log(Multi.new(), ["storage=1", "topic=bytes"], value: 1024)

      refute_received {:monitor_telemetry, _, _}

      {:ok, _} = Repo.commit(multi)

      assert_received {:monitor_telemetry, %{count: 1024},
                       %{"storage" => "1", "topic" => "bytes"}}
    end

    test "multi_log/3 emits nothing when its transaction rolls back" do
      {:error, :fail, :rollback, _} =
        Multi.new()
        |> Monitor.Public.multi_log(["storage=1", "topic=files"])
        |> Multi.run(:fail, fn _, _ -> {:error, :rollback} end)
        |> Repo.commit()

      refute_received {:monitor_telemetry, _, _}
      assert [] = from(Monitor.EventModel) |> Repo.all()

      {:ok, _} = Repo.commit(Multi.new())
      refute_received {:monitor_telemetry, _, _}
    end

    test "multi_log/3 in a nested commit emits nothing when the outer transaction rolls back" do
      {:error, :fail, :rollback, _} =
        Multi.new()
        |> Multi.run(:nested, fn _, _ -> Monitor.Public.log(["storage=1", "topic=files"]) end)
        |> Multi.run(:fail, fn _, _ -> {:error, :rollback} end)
        |> Repo.commit()

      refute_received {:monitor_telemetry, _, _}
    end

    test "multi_log/3 in a nested commit emits once the outer transaction commits" do
      {:ok, _} =
        Multi.new()
        |> Multi.run(:nested, fn _, _ ->
          result = Monitor.Public.log(["storage=1", "topic=files"])
          refute_received {:monitor_telemetry, _, _}
          result
        end)
        |> Repo.commit()

      assert_received {:monitor_telemetry, %{count: 1}, %{"storage" => "1", "topic" => "files"}}
      refute_received {:monitor_telemetry, _, _}
    end

    test "reset/1 emits nothing" do
      Monitor.Public.log(["storage=1", "topic=bytes"], value: 10)
      assert_received {:monitor_telemetry, %{count: 10}, _}

      Monitor.Public.reset(["storage=1", "topic=bytes"])

      refute_received {:monitor_telemetry, _, _}
      assert 0 = Monitor.Public.sum(["storage=1", "topic=bytes"])
    end
  end

  def forward_telemetry(_event, measurements, metadata, test_pid) do
    if self() == test_pid do
      send(test_pid, {:monitor_telemetry, measurements, metadata})
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
