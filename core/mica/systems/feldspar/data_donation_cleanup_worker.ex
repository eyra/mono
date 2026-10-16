defmodule Systems.Feldspar.DataDonationCleanupWorker do
  @moduledoc """
  Scheduled Oban worker that cleans up old data donation files.

  Deletes files that are older than the configured retention period (default 2 weeks).
  This is the only mechanism that deletes local data donation files; delivery keeps them.

  Data donation files live on each node's local filesystem, but Oban's Cron plugin only
  inserts jobs on the leader node. A job without a `"node"` arg (from cron or the admin
  Actions tab) therefore fans out: it inserts one job per connected node into that node's
  local storage delivery queue. A job with a `"node"` arg cleans the folder of the node
  it runs on. A node that is disconnected during the fan-out is cleaned on the next run.
  """
  use Oban.Worker,
    priority: 3,
    max_attempts: 1

  require Logger

  alias Systems.Feldspar
  alias Systems.Storage

  # Shorter than the hourly schedule, so overlapping fan-outs don't pile up per node.
  @unique_period_seconds 50 * 60

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"node" => _} = args}) do
    retention_hours = get_retention_hours(args)
    deleted_count = Feldspar.DataDonationFolder.cleanup_older_than(retention_hours)

    if deleted_count > 0 do
      Logger.info(
        "[Feldspar.DataDonationCleanupWorker] Deleted #{deleted_count} files older than #{retention_hours}h"
      )
    end

    :ok
  end

  def perform(%Oban.Job{args: args}) do
    fan_out(args, [Node.self() | Node.list()])
  end

  @doc """
  Inserts a cleanup job for each of `nodes` into that node's local storage delivery queue.
  """
  def fan_out(args, nodes) do
    # Oban.insert_all/1 ignores `unique` on the Basic engine, so insert one by one.
    Enum.each(nodes, fn node ->
      {:ok, _} = node |> node_job(args) |> Oban.insert()
    end)
  end

  defp node_job(node, args) do
    args
    |> Map.take(["retention_hours"])
    |> Map.put("node", to_string(node))
    |> new(
      queue: Storage.Public.storage_delivery_queue(node),
      unique: [period: @unique_period_seconds, keys: [:node]]
    )
  end

  defp get_retention_hours(args) do
    Map.get(args, "retention_hours") ||
      Application.get_env(:core, :feldspar_data_donation)[:retention_hours] ||
      336
  end
end
