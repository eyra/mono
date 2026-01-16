defmodule Systems.Storage.BlobCleanupWorkerTest do
  use Core.DataCase, async: true
  use Oban.Testing, repo: Core.Repo

  alias Systems.Storage.BlobCleanupWorker
  alias Systems.Storage.PendingBlobModel

  defp time_ago(hours) do
    NaiveDateTime.utc_now()
    |> NaiveDateTime.add(-hours * 3600, :second)
    |> NaiveDateTime.truncate(:second)
  end

  describe "perform/1" do
    test "deletes blobs older than default 24 hours" do
      # Create old blob (simulate 25 hours ago)
      old_time = time_ago(25)

      {:ok, old_blob} =
        PendingBlobModel.prepare("old data")
        |> Repo.insert()

      # Manually update inserted_at to make it old
      old_blob
      |> Ecto.Changeset.change(%{inserted_at: old_time})
      |> Repo.update!()

      # Create recent blob
      {:ok, recent_blob} =
        PendingBlobModel.prepare("recent data")
        |> Repo.insert()

      # Run cleanup worker
      assert :ok = perform_job(BlobCleanupWorker, %{})

      # Old blob should be deleted
      assert Repo.get(PendingBlobModel, old_blob.id) == nil

      # Recent blob should still exist
      assert Repo.get(PendingBlobModel, recent_blob.id) != nil
    end

    test "respects custom max_age_hours parameter" do
      # Create blob 2 hours old
      two_hours_ago = time_ago(2)

      {:ok, blob} =
        PendingBlobModel.prepare("test data")
        |> Repo.insert()

      blob
      |> Ecto.Changeset.change(%{inserted_at: two_hours_ago})
      |> Repo.update!()

      # Run with 1 hour max age - should delete
      assert :ok = perform_job(BlobCleanupWorker, %{"max_age_hours" => 1})
      assert Repo.get(PendingBlobModel, blob.id) == nil
    end

    test "does not delete blobs within max age" do
      # Create blob 1 hour old
      one_hour_ago = time_ago(1)

      {:ok, blob} =
        PendingBlobModel.prepare("test data")
        |> Repo.insert()

      blob
      |> Ecto.Changeset.change(%{inserted_at: one_hour_ago})
      |> Repo.update!()

      # Run with 2 hour max age - should NOT delete
      assert :ok = perform_job(BlobCleanupWorker, %{"max_age_hours" => 2})
      assert Repo.get(PendingBlobModel, blob.id) != nil
    end

    test "succeeds when no blobs to cleanup" do
      # No blobs in database
      assert :ok = perform_job(BlobCleanupWorker, %{})
    end

    test "deletes multiple old blobs" do
      old_time = time_ago(25)

      # Create multiple old blobs
      old_blob_ids =
        for i <- 1..5 do
          {:ok, blob} =
            PendingBlobModel.prepare("old data #{i}")
            |> Repo.insert()

          blob
          |> Ecto.Changeset.change(%{inserted_at: old_time})
          |> Repo.update!()

          blob.id
        end

      # Run cleanup
      assert :ok = perform_job(BlobCleanupWorker, %{})

      # All old blobs should be deleted
      for id <- old_blob_ids do
        assert Repo.get(PendingBlobModel, id) == nil
      end
    end
  end
end
