defmodule Systems.Feldspar.DataDonationCleanupWorkerTest do
  use Core.DataCase, async: false
  use Oban.Testing, repo: Core.Repo

  alias Systems.Feldspar.DataDonationCleanupWorker
  alias Systems.Feldspar.DataDonationFolder

  @node_queue "storage_delivery_local_#{Node.self()}"

  describe "fan-out (no node arg)" do
    test "inserts one cleanup job into the local queue of each node" do
      assert :ok = DataDonationCleanupWorker.fan_out(%{}, [:"core@node-01", :"core@node-02"])

      assert [_] =
               all_enqueued(
                 worker: DataDonationCleanupWorker,
                 queue: "storage_delivery_local_core@node-01",
                 args: %{"node" => "core@node-01"}
               )

      assert [_] =
               all_enqueued(
                 worker: DataDonationCleanupWorker,
                 queue: "storage_delivery_local_core@node-02",
                 args: %{"node" => "core@node-02"}
               )

      assert length(all_enqueued(worker: DataDonationCleanupWorker)) == 2
    end

    test "perform/1 fans out to the current node" do
      assert :ok = perform_job(DataDonationCleanupWorker, %{})

      assert_enqueued(
        worker: DataDonationCleanupWorker,
        queue: @node_queue,
        args: %{"node" => to_string(Node.self())}
      )
    end

    test "passes retention_hours on to the node jobs" do
      assert :ok = perform_job(DataDonationCleanupWorker, %{"retention_hours" => 1})

      assert_enqueued(
        worker: DataDonationCleanupWorker,
        queue: @node_queue,
        args: %{"node" => to_string(Node.self()), "retention_hours" => 1}
      )
    end

    test "does not pile up node jobs when fan-outs overlap" do
      nodes = [:"core@node-01", :"core@node-02"]

      assert :ok = DataDonationCleanupWorker.fan_out(%{}, nodes)
      assert :ok = DataDonationCleanupWorker.fan_out(%{}, nodes)

      assert length(all_enqueued(worker: DataDonationCleanupWorker)) == 2
    end

    test "a completed node job does not block the admin trigger" do
      assert :ok = DataDonationCleanupWorker.fan_out(%{}, [Node.self()])

      Repo.update_all(Oban.Job,
        set: [state: "completed", completed_at: DateTime.utc_now()]
      )

      assert :ok = perform_job(DataDonationCleanupWorker, %{})

      assert [_] =
               all_enqueued(
                 worker: DataDonationCleanupWorker,
                 queue: @node_queue,
                 args: %{"node" => to_string(Node.self())}
               )
    end
  end

  describe "node job" do
    setup do
      on_exit(fn -> Enum.each(["cleanup-old", "cleanup-new"], &DataDonationFolder.delete/1) end)
      %{folder: Application.get_env(:core, :feldspar_data_donation)[:path]}
    end

    test "deletes local files older than the retention period", %{folder: folder} do
      {:ok, _} = DataDonationFolder.store("old", "cleanup-old")
      {:ok, _} = DataDonationFolder.store("new", "cleanup-new")

      two_hours_ago = System.os_time(:second) - 2 * 3600
      File.touch!(Path.join(folder, "cleanup-old.dat"), two_hours_ago)

      assert :ok =
               perform_job(DataDonationCleanupWorker, %{
                 "node" => to_string(Node.self()),
                 "retention_hours" => 1
               })

      ids = DataDonationFolder.list_all() |> Enum.map(& &1.id)
      refute "cleanup-old" in ids
      assert "cleanup-new" in ids
    end
  end
end
