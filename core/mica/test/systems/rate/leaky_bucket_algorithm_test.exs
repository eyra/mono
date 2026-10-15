defmodule Systems.Rate.LeakyBucketAlgorithmTest do
  use ExUnit.Case, async: true

  alias Systems.Rate.Quota
  alias Systems.Rate.LeakyBucket, as: Bucket
  alias Systems.Rate.LeakyBucketState, as: State
  alias Systems.Rate.LeakyBucketAlgorithm, as: Algorithm

  @prune_interval 60 * 60 * 1000

  describe "global byte/s" do
    setup do
      limit = 1000

      quota = %Quota{
        service: :azure_blob,
        limit: limit,
        unit: :byte,
        window: :second,
        scope: :global
      }

      %{state: State.init(@prune_interval, [quota])}
    end

    test "global 1000 byte/sec :granted", %{state: state} do
      assert {
               :granted,
               %State{
                 buckets: %{
                   "1000:byte/second@azure_blob" => %Bucket{
                     capacity: 1000,
                     level: 1000,
                     drop_rate: 1.0
                   }
                 }
               }
             } = Algorithm.request_permission(state, :azure_blob, "192.168.1.2", 1000)
    end

    test "global 1000 byte/sec 2x1000 :denied" do
      now = DateTime.now!("Etc/UTC")

      quota = %Quota{
        service: :azure_blob,
        limit: 1000,
        unit: :byte,
        window: :second,
        scope: :global
      }

      bucket = %Bucket{capacity: 1000, level: 1000, drop_rate: 1, updated_at: now}

      state = %State{
        quotas: [quota],
        buckets: %{"1000:byte/second@azure_blob" => bucket},
        prune_interval: @prune_interval
      }

      assert {{:denied, _}, _} =
               Algorithm.request_permission(state, :azure_blob, "192.168.1.2", 1000)
    end

    test "global 1000 byte/sec 3x500 :denied", %{state: state} do
      now = DateTime.now!("Etc/UTC")
      bucket = %Bucket{capacity: 1000, level: 0, drop_rate: 1, updated_at: now}
      state = State.update(state, "1000:byte/second@azure_blob", bucket)

      assert {:granted, state} =
               Algorithm.request_permission(state, :azure_blob, "192.168.1.2", 500)

      assert {:granted, state} =
               Algorithm.request_permission(state, :azure_blob, "192.168.1.3", 500)

      assert {{:denied, _}, _} =
               Algorithm.request_permission(state, :azure_blob, "192.168.1.4", 500)
    end
  end

  describe "global call/s" do
    setup do
      limit = 1

      quota = %Quota{
        service: :azure_blob,
        limit: limit,
        unit: :call,
        window: :second,
        scope: :global
      }

      %{state: State.init(@prune_interval, [quota])}
    end

    test "global 1 call/sec :granted", %{state: state} do
      assert {
               :granted,
               %State{
                 buckets: %{
                   "1:call/second@azure_blob" => %Bucket{capacity: 1, level: 1, drop_rate: 0.001}
                 }
               }
             } = Algorithm.request_permission(state, :azure_blob, "192.168.1.2", 1000)
    end

    test "global 2 call/sec 3x :denied" do
      now = DateTime.now!("Etc/UTC")
      quota = %Quota{service: :azure_blob, limit: 2, unit: :call, window: :second, scope: :global}
      bucket = %Bucket{capacity: 2, level: 0, drop_rate: 0.001, updated_at: now}

      state = %State{
        quotas: [quota],
        buckets: %{"2:call/second@azure_blob" => bucket},
        prune_interval: @prune_interval
      }

      assert {:granted, state} =
               Algorithm.request_permission(state, :azure_blob, "192.168.1.2", 1000)

      assert {:granted, state} =
               Algorithm.request_permission(state, :azure_blob, "192.168.1.2", 1000)

      assert {{:denied, _}, _} =
               Algorithm.request_permission(state, :azure_blob, "192.168.1.2", 1000)
    end
  end

  describe "local call/s" do
    setup do
      limit = 2

      quota = %Quota{
        service: :azure_blob,
        limit: limit,
        unit: :call,
        window: :second,
        scope: :local
      }

      %{state: State.init(@prune_interval, [quota])}
    end

    test "local 2 call/sec :granted", %{state: state} do
      assert {
               :granted,
               %State{
                 buckets: %{
                   "2:call/second@azure_blob=>192.168.1.2" => %Bucket{
                     capacity: 2,
                     level: 1,
                     drop_rate: 0.002
                   }
                 }
               }
             } = Algorithm.request_permission(state, :azure_blob, "192.168.1.2", 1000)
    end

    test "global 2 call/sec 3x :denied", %{state: state} do
      {:granted, state} = Algorithm.request_permission(state, :azure_blob, "192.168.1.2", 1000)
      {:granted, state} = Algorithm.request_permission(state, :azure_blob, "192.168.1.2", 1000)

      assert {
               {:denied, _},
               %State{
                 buckets: %{
                   "2:call/second@azure_blob=>192.168.1.2" => %Bucket{
                     capacity: 2,
                     drop_rate: 0.002,
                     level: level
                   }
                 }
               }
             } = Algorithm.request_permission(state, :azure_blob, "192.168.1.2", 1000)

      assert ceil(level) == 2
    end
  end

  describe "local byte/s" do
    setup do
      limit = 1000

      quota = %Quota{
        service: :azure_blob,
        limit: limit,
        unit: :byte,
        window: :second,
        scope: :local
      }

      %{state: State.init(@prune_interval, [quota])}
    end

    test "local 1000 byte/sec :granted", %{state: state} do
      assert {
               :granted,
               %State{
                 buckets: %{
                   "1000:byte/second@azure_blob=>192.168.1.2" => %Bucket{
                     capacity: 1000,
                     level: 1000,
                     drop_rate: 1.0
                   }
                 }
               }
             } = Algorithm.request_permission(state, :azure_blob, "192.168.1.2", 1000)
    end

    test "local 1000 byte/sec :denied", %{state: state} do
      {:granted, state} = Algorithm.request_permission(state, :azure_blob, "192.168.1.2", 1000)

      assert {
               {:denied, _},
               %State{
                 buckets: %{
                   "1000:byte/second@azure_blob=>192.168.1.2" => %Bucket{level: 1000}
                 }
               }
             } = Algorithm.request_permission(state, :azure_blob, "192.168.1.2", 250)
    end

    test "local 1000 byte/sec :granted with multiple clients", %{state: state} do
      {:granted, state} = Algorithm.request_permission(state, :azure_blob, "192.168.1.2", 500)
      {:granted, state} = Algorithm.request_permission(state, :azure_blob, "192.168.1.3", 600)
      {:granted, state} = Algorithm.request_permission(state, :azure_blob, "192.168.1.4", 700)

      %{buckets: buckets} = state

      assert Enum.count(buckets) == 3

      assert %{
               "1000:byte/second@azure_blob=>192.168.1.2" => %Bucket{level: 500},
               "1000:byte/second@azure_blob=>192.168.1.3" => %Bucket{level: 600},
               "1000:byte/second@azure_blob=>192.168.1.4" => %Bucket{level: 700}
             } = buckets
    end
  end

  describe "local mixed byte/s & call/2" do
    setup do
      quotas = [
        %Quota{
          service: :azure_blob,
          limit: 1000,
          unit: :byte,
          window: :minute,
          scope: :local
        },
        %Quota{
          service: :azure_blob,
          limit: 60,
          unit: :call,
          window: :minute,
          scope: :local
        }
      ]

      %{state: State.init(@prune_interval, quotas)}
    end

    test "local 1 call :granted", %{state: state} do
      assert {
               :granted,
               %State{
                 buckets: %{
                   "60:call/minute@azure_blob=>192.168.1.2" => %Bucket{level: 1},
                   "1000:byte/minute@azure_blob=>192.168.1.2" => %Bucket{level: 1000}
                 }
               }
             } = Algorithm.request_permission(state, :azure_blob, "192.168.1.2", 1000)
    end

    test "local 60 call/minute :denied", %{state: state} do
      state =
        Enum.reduce(1..60, state, fn _i, state ->
          {:granted, state} = Algorithm.request_permission(state, :azure_blob, "192.168.1.2", 2)
          state
        end)

      assert {
               {:denied, _},
               %State{
                 buckets: %{
                   "60:call/minute@azure_blob=>192.168.1.2" => %Bucket{level: level_call},
                   "1000:byte/minute@azure_blob=>192.168.1.2" => %Bucket{level: level_byte}
                 }
               }
             } = Algorithm.request_permission(state, :azure_blob, "192.168.1.2", 2)

      assert ceil(level_call) == 60
      assert ceil(level_byte) == 120
    end
  end

  describe "mixed local & global" do
    setup do
      quotas = [
        %Quota{
          service: :azure_blob,
          limit: 1000,
          unit: :byte,
          window: :minute,
          scope: :global
        },
        %Quota{
          service: :azure_blob,
          limit: 60,
          unit: :call,
          window: :minute,
          scope: :local
        }
      ]

      %{state: State.init(@prune_interval, quotas)}
    end

    test "local 1 call :granted", %{state: state} do
      assert {
               :granted,
               %State{
                 buckets: %{
                   "60:call/minute@azure_blob=>192.168.1.2" => %Bucket{level: level},
                   "1000:byte/minute@azure_blob" => %Bucket{level: 1000}
                 }
               }
             } = Algorithm.request_permission(state, :azure_blob, "192.168.1.2", 1000)

      assert ceil(level) == 1
    end

    test "local 60 call/minute :denied", %{state: state} do
      state =
        Enum.reduce(1..60, state, fn _i, state ->
          {:granted, state} = Algorithm.request_permission(state, :azure_blob, "192.168.1.2", 1)
          {:granted, state} = Algorithm.request_permission(state, :azure_blob, "192.168.1.3", 1)
          state
        end)

      assert {
               {:denied, _},
               %State{
                 buckets: %{
                   "60:call/minute@azure_blob=>192.168.1.2" => %Bucket{level: level2},
                   "60:call/minute@azure_blob=>192.168.1.3" => %Bucket{level: level3},
                   "1000:byte/minute@azure_blob" => %Bucket{level: _}
                 }
               }
             } = Algorithm.request_permission(state, :azure_blob, "192.168.1.2", 1)

      assert ceil(level2) == 60
      assert ceil(level3) == 60
    end
  end
end
