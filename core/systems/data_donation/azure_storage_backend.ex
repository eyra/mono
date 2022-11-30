defmodule Systems.DataDonation.AzureStorageBackend do
  defmodule DeliveryError do
    @moduledoc false
    defexception [:message]
  end

  @behaviour Systems.DataDonation.StorageBackend

  require Logger

  def store(
        %{"participant" => participant, "key" => donation_key},
        %{"storage_info" => %{"key" => root_key}},
        data
      ) do
    Logger.info("[AzureStorageBackend] store begin")

    path = path(root_key, participant, donation_key)

    Logger.info("[AzureStorageBackend] store; path")

    config = config()

    Logger.info("[AzureStorageBackend] store: path")

    url = url(config, path)

    Logger.info("[AzureStorageBackend] store: url=#{url}")

    headers = [
      {"Content-Type", "text/plain"},
      {"x-ms-blob-type", "BlockBlob"}
    ]

    HTTPoison.put(url, data, headers)
    |> case do
      {:ok, %{status_code: 201}} ->
        :ok

      {_, %{status_code: status_code, body: body}} ->
        {:error, "status_code=#{status_code},message=#{body}"}

      {_, response} ->
        {:error, response}
    end
  end

  def path(root_key, participant, donation_key) do
    "#{root_key}/#{participant}/#{donation_key}.json"
  end

  defp url(
         [
           storage_account_name: storage_account_name,
           container: container,
           sas_token: sas_token
         ],
         path
       ) do
    url = "https://#{storage_account_name}.blob.core.windows.net/#{container}/#{path}#{sas_token}"
    Logger.info("[AzureStorageBackend] url=#{url}")

    url
  end

  defp url(config, _) do
    Logger.error("[AzureStorageBackend] invalid config=#{config}")
    raise DeliveryError, "Could not deliver donated data, invalid config"
  end

  defp config() do
    Application.fetch_env!(:core, :azure_storage_backend)
  end
end
