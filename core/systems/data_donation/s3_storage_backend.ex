defmodule Systems.DataDonation.S3StorageBackend do
  @behaviour Systems.DataDonation.StorageBackend

  alias ExAws.S3

  def store(%{participant: participant} = _state, _vm, data) do
    [data]
    |> S3.upload(bucket(), path(participant))
    |> ExAws.request()
  end

  defp bucket do
    :core
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.fetch!(:bucket)
  end

  def path(participant) do
    timestamp = "Europe/Amsterdam" |> DateTime.now!() |> DateTime.to_iso8601(:basic)
    "#{participant}/#{timestamp}.json"
  end
end
