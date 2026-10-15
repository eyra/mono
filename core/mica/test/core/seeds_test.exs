defmodule Core.SeedsTest do
  use Core.DataCase, async: false

  setup do
    original = Application.get_env(:core, :deploy_env)
    on_exit(fn -> Application.put_env(:core, :deploy_env, original) end)
    :ok
  end

  describe "seed/0" do
    test "dispatches to Local for :local deploy_env" do
      Application.put_env(:core, :deploy_env, :local)
      assert :ok = Core.Seeds.seed()
    end

    test "dispatches to Dev for :dev deploy_env" do
      Application.put_env(:core, :deploy_env, :dev)
      assert :ok = Core.Seeds.seed()
    end

    test "dispatches to Test for :test deploy_env" do
      Application.put_env(:core, :deploy_env, :test)
      assert :ok = Core.Seeds.seed()
    end

    test "dispatches to Staging for :staging deploy_env" do
      Application.put_env(:core, :deploy_env, :staging)
      assert :ok = Core.Seeds.seed()
    end

    test "dispatches to Prod for :prod deploy_env" do
      Application.put_env(:core, :deploy_env, :prod)
      assert :ok = Core.Seeds.seed()
    end

    test "skips env-specific seeds for unknown deploy_env" do
      Application.put_env(:core, :deploy_env, :unknown)
      assert :ok = Core.Seeds.seed()
    end
  end
end
