defmodule Systems.Storage.JobDataCleanupWorker do
  @moduledoc """
  Scheduled Oban worker that cleans up finished job data from storage_job_data.

  Deletes records that are:
  - Marked as finished (successfully delivered to S3)
  - Older than 2 weeks (default)

  This gives time for debugging and investigation if issues arise,
  while eventually freeing up database storage.
  """
  use Oban.Worker,
    queue: :maintenance,
    priority: 3,
    max_attempts: 1

  require Logger

  import Ecto.Query

  alias Core.Repo
  alias Systems.Storage

  # Default: clean up finished job data older than 2 weeks (336 hours)
  @default_max_age_hours 336

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    max_age_hours = Map.get(args, "max_age_hours", @default_max_age_hours)
    cutoff_time = NaiveDateTime.utc_now() |> NaiveDateTime.add(-max_age_hours * 3600, :second)

    # Only delete finished job data older than the cutoff
    {deleted_count, _} =
      from(j in Storage.JobDataModel,
        where: j.status == :finished,
        where: j.inserted_at < ^cutoff_time
      )
      |> Repo.delete_all()

    if deleted_count > 0 do
      Logger.info(
        "[Storage.JobDataCleanupWorker] Deleted #{deleted_count} finished job data records"
      )
    end

    :ok
  end
end
