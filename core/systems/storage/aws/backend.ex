defmodule Systems.Storage.AWS.Backend do
  @behaviour Systems.Storage.Backend

  require Logger
  alias ExAws.S3

  @impl true
  def store(
        %{"s3_bucket_name" => bucket} = _endpoint,
        data,
        %{"identifier" => identifier}
      ) do
    case [data]
         |> S3.upload(bucket, filename(identifier))
         |> ExAws.request() do
      {:ok, _response} -> :ok
      {:error, reason} -> {:error, reason}
    end
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

  @impl true
  def connected?(_endpoint) do
    # FIXME
    false
  end

  @impl true
  def filename(identifier), do: Systems.Storage.Filename.generate(identifier)
end
