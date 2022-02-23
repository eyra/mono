defmodule Systems.DataDonation.S3StorageBackend do
  @behaviour Systems.DataDonation.StorageBackend

  alias ExAws.S3

  def store(participant_id, data) do
    [data]
    |> S3.upload(bucket(), path(participant_id))
    |> ExAws.request()
  end

  defp bucket do
    :core
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.fetch!(:bucket)
  end

  def path(participant_id) do
    timestamp = "Europe/Amsterdam" |> DateTime.now!() |> DateTime.to_iso8601(:basic)
    "#{participant_id}/#{timestamp}.json"
  end
end
