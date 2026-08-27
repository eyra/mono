defmodule Systems.Fund.AutoApproveWorkerTest do
  use Core.DataCase
  use Oban.Testing, repo: Core.Repo

  import Ecto.Query
  import Systems.Fund.TestHelper

  alias Core.Factories
  alias Core.Repo
  alias Systems.Fund
  alias Systems.Fund.AutoApproveWorker

  @approve_timeout 14

  setup do
    currency = Fund.Factories.create_currency("fake_currency", :legal, "ƒ", 2)
    fund = Fund.Factories.create_fund("test", currency)
    {:ok, currency: currency, fund: fund}
  end

  defp create_reward(fund, suffix) do
    participant = Factories.insert!(:member, %{creator: false})
    key = "user:#{participant.id},fund:#{fund.id},#{suffix}"
    {:ok, _} = Fund.Public.create_reward(fund, 1000, participant, key)
    key
  end

  defp create_pending_reward(fund, suffix) do
    key = create_reward(fund, suffix)
    {:ok, _} = mark_pending_approval(key)
    key
  end

  defp backdate(key, days_ago) do
    timestamp =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.add(-days_ago * 24 * 60 * 60, :second)
      |> NaiveDateTime.truncate(:second)

    Repo.update_all(from(r in Fund.RewardModel, where: r.idempotence_key == ^key),
      set: [updated_at: timestamp]
    )

    key
  end

  defp status(key) do
    %{status: status} = Fund.Public.get_reward(key, [])
    status
  end

  describe "perform/1" do
    test "approves a reward that has been pending past the timeout", %{fund: fund} do
      key =
        fund
        |> create_pending_reward("stale")
        |> backdate(@approve_timeout + 1)

      assert :ok = perform_job(AutoApproveWorker, %{})
      assert status(key) == :approved
    end

    test "creates a wallet payment for the auto-approved reward", %{fund: fund} do
      key =
        fund
        |> create_pending_reward("stale-payment")
        |> backdate(@approve_timeout + 1)

      assert :ok = perform_job(AutoApproveWorker, %{})

      %{payment_id: payment_id} = Fund.Public.get_reward(key, [])
      assert payment_id
    end

    test "skips a reward still inside the timeout window", %{fund: fund} do
      key =
        fund
        |> create_pending_reward("fresh")
        |> backdate(@approve_timeout - 1)

      assert :ok = perform_job(AutoApproveWorker, %{})
      assert status(key) == :pending_approval
    end

    test "skips a reward that is still :reserved", %{fund: fund} do
      key =
        fund
        |> create_reward("reserved")
        |> backdate(@approve_timeout + 1)

      assert :ok = perform_job(AutoApproveWorker, %{})
      assert status(key) == :reserved
    end

    test "leaves an already approved reward untouched", %{fund: fund} do
      key = create_pending_reward(fund, "approved")
      {:ok, _} = approve_reward(key)
      %{payment_id: payment_id} = Fund.Public.get_reward(key, [])
      backdate(key, @approve_timeout + 1)

      assert :ok = perform_job(AutoApproveWorker, %{})

      assert status(key) == :approved
      assert %{payment_id: ^payment_id} = Fund.Public.get_reward(key, [])
    end

    test "leaves a rejected reward untouched", %{fund: fund} do
      key = create_pending_reward(fund, "rejected")
      {:ok, _} = reject_reward(key)
      backdate(key, @approve_timeout + 1)

      assert :ok = perform_job(AutoApproveWorker, %{})
      assert status(key) == :rejected
    end

    test "approves every stale reward in a single run", %{fund: fund} do
      keys =
        for suffix <- ["stale-a", "stale-b", "stale-c"] do
          fund
          |> create_pending_reward(suffix)
          |> backdate(@approve_timeout + 1)
        end

      assert :ok = perform_job(AutoApproveWorker, %{})
      assert Enum.all?(keys, &(status(&1) == :approved))
    end

    test "is idempotent across repeated runs", %{fund: fund} do
      key =
        fund
        |> create_pending_reward("repeat")
        |> backdate(@approve_timeout + 1)

      assert :ok = perform_job(AutoApproveWorker, %{})
      %{payment_id: payment_id} = Fund.Public.get_reward(key, [])

      assert :ok = perform_job(AutoApproveWorker, %{})

      assert status(key) == :approved
      assert %{payment_id: ^payment_id} = Fund.Public.get_reward(key, [])
    end

    test "is a no-op when nothing is pending", %{fund: _fund} do
      assert :ok = perform_job(AutoApproveWorker, %{})
    end
  end

  describe "uniqueness" do
    test "does not overlap with an already scheduled or running job" do
      unique = Keyword.fetch!(AutoApproveWorker.__opts__(), :unique)

      assert unique[:period] == :infinity
      assert Enum.sort(unique[:states]) == [:available, :executing, :retryable, :scheduled]
    end
  end

  describe "telemetry" do
    setup do
      handler = "auto-approve-test-#{System.unique_integer([:positive])}"
      parent = self()

      :telemetry.attach(
        handler,
        [:fund, :auto_approve, :stop],
        fn _event, measurements, metadata, _config ->
          send(parent, {:telemetry, measurements, metadata})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler) end)
      :ok
    end

    test "emits the count of rewards approved by this run", %{fund: fund} do
      for suffix <- ["telemetry-a", "telemetry-b"] do
        fund
        |> create_pending_reward(suffix)
        |> backdate(@approve_timeout + 1)
      end

      assert :ok = perform_job(AutoApproveWorker, %{})

      assert_receive {:telemetry, %{count: 2, failed: 0}, _metadata}
    end

    test "does not count rewards left inside the timeout window", %{fund: fund} do
      fund
      |> create_pending_reward("telemetry-fresh")
      |> backdate(@approve_timeout - 1)

      assert :ok = perform_job(AutoApproveWorker, %{})

      assert_receive {:telemetry, %{count: 0, failed: 0}, _metadata}
    end

    test "emits a zero count when nothing is pending" do
      assert :ok = perform_job(AutoApproveWorker, %{})

      assert_receive {:telemetry, %{count: 0, failed: 0}, _metadata}
    end

    test "reports a duration measurement" do
      assert :ok = perform_job(AutoApproveWorker, %{})

      assert_receive {:telemetry, %{duration: duration}, _metadata}
      assert is_integer(duration)
    end
  end
end
