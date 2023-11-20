defmodule Systems.Storage.AWS.Backend do
  @behaviour Systems.Storage.Backend

  alias ExAws.S3

  def store(
        %{"s3_bucket_name" => bucket} = _endpoint,
        panel_info,
        data,
        meta_data
      ) do
    [data]
    |> S3.upload(bucket, path(panel_info, meta_data))
    |> ExAws.request()
  end

  defp path(%{"participant" => participant}, %{"key" => key, "timestamp" => timestamp}) do
    "#{participant}/#{key}/#{timestamp}.json"
  end

  defp path(%{"participant" => participant}, %{"key" => key}) do
    "#{key}/#{participant}.json"
  end
end
