defmodule Systems.Storage.AWS.Backend do
  @behaviour Systems.Storage.Backend

  require Logger
  alias ExAws.S3

  @impl true
  def store(
        %{"s3_bucket_name" => bucket} = _endpoint,
        data,
        meta_data
      ) do
    [data]
    |> S3.upload(bucket, filename(meta_data))
    |> ExAws.request()
  end

  @impl true
  def list_files(_endpoint) do
    Logger.error("Not yet implemented: list_files/1")
    {:error, :not_implemented}
  end

  @impl true
  def delete_files(_endpoint) do
    Logger.error("Not yet implemented: delete_files/1")
    {:error, :not_implemented}
  end

  defp filename(%{"identifier" => identifier}) do
    identifier
    |> Enum.map_join("_", fn [key, value] -> "#{key}-#{value}" end)
    |> then(&"#{&1}.json")
  end
end
