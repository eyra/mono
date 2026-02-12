defmodule Systems.Storage.JobScheduler.Oban do
  @moduledoc """
  Default JobScheduler implementation using Oban.
  """
  @behaviour Systems.Storage.JobScheduler

  @impl true
  def insert(changeset) do
    Oban.insert(changeset)
  end
end
