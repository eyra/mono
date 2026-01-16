defmodule Systems.Storage.BlobCleanupWorker do
  @moduledoc """
  Scheduled Oban worker that cleans up orphaned blobs from storage_pending_blobs.

  Blobs can become orphaned when:
  - Oban job fails all retry attempts and is discarded
  - System crash before job completion

  By default, deletes blobs older than 24 hours.
  """
  use Oban.Worker,
    queue: :maintenance,
    priority: 3,
    max_attempts: 1

  require Logger

  import Ecto.Query

  alias Core.Repo
  alias Systems.Storage

  # Default: clean up blobs older than 24 hours
  @default_max_age_hours 24

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    max_age_hours = Map.get(args, "max_age_hours", @default_max_age_hours)
    cutoff_time = NaiveDateTime.utc_now() |> NaiveDateTime.add(-max_age_hours * 3600, :second)

    # Find and delete orphaned blobs
    {deleted_count, _} =
      from(b in Storage.PendingBlobModel,
        where: b.inserted_at < ^cutoff_time
      )
      |> Repo.delete_all()

    if deleted_count > 0 do
      Logger.info("[Storage.BlobCleanupWorker] Deleted #{deleted_count} orphaned blobs")
    end

    :ok
  end
end
