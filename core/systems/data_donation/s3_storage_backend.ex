defmodule Systems.DataDonation.S3StorageBackend do
  @behaviour Systems.DataDonation.StorageBackend

  alias Systems.DataDonation.ToolModel
  alias ExAws.S3

  def store(%ToolModel{} = tool, data) do
    [data]
    |> S3.upload(bucket(), path(tool))
    |> ExAws.request()
  end

  defp bucket do
    :core
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.fetch!(:bucket)
  end

  def path(tool) do
    tool_id = Integer.to_string(tool.id)
    timestamp = "Europe/Amsterdam" |> DateTime.now!() |> DateTime.to_iso8601(:basic)
    "#{tool_id}/#{timestamp}.json"
  end
end
