defmodule Systems.Feldspar.DataDonationCleanupWorker do
  @moduledoc """
  Scheduled Oban worker that cleans up old data donation files.

  Deletes files that are older than the configured retention period (default 2 weeks).
  This provides a safety net for orphaned files while eventually freeing up disk space.

  Can also be triggered manually via the admin Actions tab.
  """
  # Queue is set dynamically via Storage.Private.storage_delivery_queue() in cron config (runtime.exs)
  # This ensures cleanup runs on the node that has the local files
  use Oban.Worker,
    priority: 3,
    max_attempts: 1

  require Logger

  alias Systems.Feldspar

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    retention_hours = get_retention_hours(args)
    deleted_count = Feldspar.DataDonationFolder.cleanup_older_than(retention_hours)

    if deleted_count > 0 do
      Logger.info(
        "[Feldspar.DataDonationCleanupWorker] Deleted #{deleted_count} files older than #{retention_hours}h"
      )
    end

    :ok
  end

  defp get_retention_hours(args) do
    Map.get(args, "retention_hours") ||
      Application.get_env(:core, :feldspar_data_donation)[:retention_hours] ||
      336
  end
end
