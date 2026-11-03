defmodule Mica.SeedsTest do
  use Mica.DataCase, async: false

  setup do
    original = Application.get_env(:mica, :deploy_env)
    on_exit(fn -> Application.put_env(:mica, :deploy_env, original) end)
    :ok
  end

  describe "seed/0" do
    test "dispatches to Local for :local deploy_env" do
      Application.put_env(:mica, :deploy_env, :local)
      assert :ok = Mica.Seeds.seed()
    end

    test "dispatches to Dev for :dev deploy_env" do
      Application.put_env(:mica, :deploy_env, :dev)
      assert :ok = Mica.Seeds.seed()
    end

    test "dispatches to Test for :test deploy_env" do
      Application.put_env(:mica, :deploy_env, :test)
      assert :ok = Mica.Seeds.seed()
    end

    test "dispatches to Staging for :staging deploy_env" do
      Application.put_env(:mica, :deploy_env, :staging)
      assert :ok = Mica.Seeds.seed()
    end

    test "dispatches to Prod for :prod deploy_env" do
      Application.put_env(:mica, :deploy_env, :prod)
      assert :ok = Mica.Seeds.seed()
    end

    test "skips env-specific seeds for unknown deploy_env" do
      Application.put_env(:mica, :deploy_env, :unknown)
      assert :ok = Mica.Seeds.seed()
    end
  end

  describe "seed_systems/2" do
    defmodule NoSeedsSystem do
      use Mica.System
    end

    defmodule SeedsSystem do
      use Mica.System

      def seeds(deploy_env) do
        send(self(), {:seeded, __MODULE__, deploy_env})
        :ok
      end
    end

    defmodule OtherSeedsSystem do
      use Mica.System

      def seeds(deploy_env) do
        send(self(), {:seeded, __MODULE__, deploy_env})
        :ok
      end
    end

    test "runs the seeds of each system for the deploy env, in system order" do
      assert :ok = Mica.Seeds.seed_systems([OtherSeedsSystem, NoSeedsSystem, SeedsSystem], :dev)

      assert {:messages, [{:seeded, OtherSeedsSystem, :dev}, {:seeded, SeedsSystem, :dev}]} =
               Process.info(self(), :messages)
    end
  end
end
