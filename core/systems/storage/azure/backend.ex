defmodule Systems.Storage.Azure.Backend do
  @behaviour Systems.Storage.Backend

  require Logger

  def store(
        endpoint,
        panel_info,
        data,
        meta_data
      ) do
    path = path(panel_info, meta_data)

    headers = [
      {"Content-Type", "text/plain"},
      {"x-ms-blob-type", "BlockBlob"}
    ]

    case url(endpoint, path) do
      {:ok, url} ->
        HTTPoison.put(url, data, headers)
        |> case do
          {:ok, %{status_code: 201}} ->
            :ok

          {_, %{status_code: status_code, body: body}} ->
            {:error, "status_code=#{status_code},message=#{body}"}

          {_, response} ->
            {:error, response}
        end

      {:error, error} ->
        Logger.error("[Azure.Backend] #{error}")
        {:error, error}
    end
  end

  defp path(%{"participant" => participant}, %{"key" => key, "timestamp" => timestamp}) do
    "#{participant}/#{key}/#{timestamp}.json"
  end

  defp path(%{"participant" => participant}, %{"key" => key}) do
    "#{key}/#{participant}.json"
  end

  defp url(
         %{
           "storage_account_name" => storage_account_name,
           "container" => container,
           "sas_token" => sas_token
         },
         path
       ) do
    {:ok,
     "https://#{storage_account_name}.blob.core.windows.net/#{container}/#{path}#{sas_token}"}
  end

  defp url(_, _) do
    {:error, "Unable to deliver donation: invalid Azure config"}
  end
end
