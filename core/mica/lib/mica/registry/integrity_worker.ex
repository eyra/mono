defmodule Mica.Registry.IntegrityWorker do
  @moduledoc """
  Runs `Mica.Registry.Integrity.check/0` once a day (the `registry_integrity` cron
  of `Systems.Workflow.System`). It logs the counts, as an error when a reference
  doesn't hold, and never removes anything.
  """
  use Oban.Worker, priority: 3, max_attempts: 1

  require Logger

  alias Mica.Registry.Integrity

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    counts = Integrity.check()

    if Integrity.problems?(counts) do
      Logger.error("[Registry.Integrity] references that don't hold: #{inspect(counts)}")
    else
      Logger.info("[Registry.Integrity] all references hold: #{inspect(counts)}")
    end

    :ok
  end
end
