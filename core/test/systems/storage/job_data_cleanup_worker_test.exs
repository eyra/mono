defmodule Systems.Storage.JobDataCleanupWorkerTest do
  use Core.DataCase, async: true
  use Oban.Testing, repo: Core.Repo

  alias Systems.Storage.JobDataCleanupWorker
  alias Systems.Storage.JobDataModel

  defp time_ago(hours) do
    NaiveDateTime.utc_now()
    |> NaiveDateTime.add(-hours * 3600, :second)
    |> NaiveDateTime.truncate(:second)
  end

  describe "perform/1" do
    test "only deletes finished job data older than default 2 weeks" do
      old_time = time_ago(337)

      # Create old finished job data (should be deleted)
      {:ok, old_finished} =
        JobDataModel.prepare("old finished data")
        |> Repo.insert()

      old_finished
      |> Ecto.Changeset.change(%{inserted_at: old_time, status: :finished})
      |> Repo.update!()

      # Create old pending job data (should NOT be deleted)
      {:ok, old_pending} =
        JobDataModel.prepare("old pending data")
        |> Repo.insert()

      old_pending
      |> Ecto.Changeset.change(%{inserted_at: old_time, status: :pending})
      |> Repo.update!()

      # Create recent finished job data (should NOT be deleted)
      {:ok, recent_finished} =
        JobDataModel.prepare("recent finished data")
        |> Repo.insert()

      recent_finished
      |> Ecto.Changeset.change(%{status: :finished})
      |> Repo.update!()

      # Run cleanup worker
      assert :ok = perform_job(JobDataCleanupWorker, %{})

      # Old finished should be deleted
      assert Repo.get(JobDataModel, old_finished.id) == nil

      # Old pending should still exist
      assert Repo.get(JobDataModel, old_pending.id) != nil

      # Recent finished should still exist
      assert Repo.get(JobDataModel, recent_finished.id) != nil
    end

    test "respects custom max_age_hours parameter" do
      # Create finished job data 2 hours old
      two_hours_ago = time_ago(2)

      {:ok, job_data} =
        JobDataModel.prepare("test data")
        |> Repo.insert()

      job_data
      |> Ecto.Changeset.change(%{inserted_at: two_hours_ago, status: :finished})
      |> Repo.update!()

      # Run with 1 hour max age - should delete
      assert :ok = perform_job(JobDataCleanupWorker, %{"max_age_hours" => 1})
      assert Repo.get(JobDataModel, job_data.id) == nil
    end

    test "does not delete finished job data within max age" do
      # Create finished job data 1 hour old
      one_hour_ago = time_ago(1)

      {:ok, job_data} =
        JobDataModel.prepare("test data")
        |> Repo.insert()

      job_data
      |> Ecto.Changeset.change(%{inserted_at: one_hour_ago, status: :finished})
      |> Repo.update!()

      # Run with 2 hour max age - should NOT delete
      assert :ok = perform_job(JobDataCleanupWorker, %{"max_age_hours" => 2})
      assert Repo.get(JobDataModel, job_data.id) != nil
    end

    test "never deletes pending job data regardless of age" do
      very_old_time = time_ago(1000)

      {:ok, old_pending} =
        JobDataModel.prepare("very old pending data")
        |> Repo.insert()

      old_pending
      |> Ecto.Changeset.change(%{inserted_at: very_old_time, status: :pending})
      |> Repo.update!()

      # Run cleanup with short max age
      assert :ok = perform_job(JobDataCleanupWorker, %{"max_age_hours" => 1})

      # Pending job data should still exist even though it's very old
      assert Repo.get(JobDataModel, old_pending.id) != nil
    end

    test "succeeds when no job data to cleanup" do
      # No job data in database
      assert :ok = perform_job(JobDataCleanupWorker, %{})
    end

    test "deletes multiple old finished job data records" do
      old_time = time_ago(337)

      # Create multiple old finished job data records
      old_job_ids =
        for i <- 1..5 do
          {:ok, job_data} =
            JobDataModel.prepare("old finished data #{i}")
            |> Repo.insert()

          job_data
          |> Ecto.Changeset.change(%{inserted_at: old_time, status: :finished})
          |> Repo.update!()

          job_data.id
        end

      # Run cleanup
      assert :ok = perform_job(JobDataCleanupWorker, %{})

      # All old finished job data should be deleted
      for id <- old_job_ids do
        assert Repo.get(JobDataModel, id) == nil
      end
    end
  end
end
