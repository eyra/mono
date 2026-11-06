defmodule Systems.Storage.Azure.Backend do
  @behaviour Systems.Storage.Backend

  alias Frameworks.Utility.OutboundUrl
  alias Systems.Storage.Azure

  require Logger

  @impl true
  def store(
        endpoint,
        data,
        %{"identifier" => identifier}
      ) do
    filename = filename(identifier)

    headers = [
      {"Content-Type", "text/plain"},
      {"x-ms-blob-type", "BlockBlob"}
    ]

    case url(endpoint, filename) do
      {:ok, url} ->
        OutboundUrl.request(:put, url, headers, data, [])
        |> case do
          {:ok, 201, _headers, _body} ->
            :ok

          {:ok, status_code, _headers, body} ->
            {:error, "status_code=#{status_code},message=#{body}"}

          {:error, reason} ->
            {:error, reason}
        end

      {:error, error} ->
        Logger.error("[Azure.Backend] #{error}")
        {:error, error}
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

  def url(
        %{
          "account_name" => storage_account_name,
          "container" => container,
          "sas_token" => sas_token
        },
        filename
      ) do
    if Azure.EndpointModel.valid_account_name?(storage_account_name) do
      path = Systems.Storage.Filename.url_segment(filename)

      {:ok,
       "https://#{storage_account_name}.blob.core.windows.net/#{container}/#{path}#{sas_token}"}
    else
      {:error, "Unable to deliver donation: invalid Azure account name"}
    end
  end

  def url(_, _) do
    {:error, "Unable to deliver donation: invalid Azure config"}
  end
end
