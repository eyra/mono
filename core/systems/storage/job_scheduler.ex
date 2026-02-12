defmodule Systems.Storage.JobScheduler do
  @moduledoc """
  Behaviour for scheduling storage delivery jobs.
  Wraps Oban to allow mocking in tests.
  """

  @callback insert(Oban.Job.changeset()) :: {:ok, Oban.Job.t()} | {:error, Ecto.Changeset.t()}

  def insert(changeset) do
    impl().insert(changeset)
  end

  defp impl do
    Application.get_env(:core, :storage)[:job_scheduler]
  end
end
