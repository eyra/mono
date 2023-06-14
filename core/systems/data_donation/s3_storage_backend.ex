defmodule Systems.DataDonation.S3StorageBackend do
  @behaviour Systems.DataDonation.StorageBackend

  alias ExAws.S3

  def store(
        state,
        %{storage_info: %{key: key}} = _vm,
        data
      ) do
    [data]
    |> S3.upload(bucket(), path(key, state))
    |> ExAws.request()
  end

  defp bucket do
    :core
    |> Application.fetch_env!(:s3)
    |> Keyword.fetch!(:bucket)
  end

  defp path(key, %{"participant" => participant, "timestamp" => timestamp} = _state) do
    "#{key}/#{participant}/#{timestamp}.json"
  end

  defp path(key, %{"participant" => participant} = _state) do
    "#{key}/#{participant}.json"
  end
end
