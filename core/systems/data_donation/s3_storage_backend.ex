defmodule Systems.DataDonation.S3StorageBackend do
  @behaviour Systems.DataDonation.StorageBackend

  alias ExAws.S3

  def store(
        %{"participant" => participant, "timestamp" => timestamp} = _state,
        %{storage_info: %{key: key}} = _vm,
        data
      ) do
    [data]
    |> S3.upload(bucket(), path(key, participant, timestamp))
    |> ExAws.request()
  end

  defp bucket do
    :core
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.fetch!(:bucket)
  end

  def path(key, participant, timestamp) do
    "#{key}/#{participant}/#{timestamp}.json"
  end
end
