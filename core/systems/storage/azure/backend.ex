defmodule Systems.Storage.Azure.Backend do
  @behaviour Systems.Storage.Backend

  require Logger

  @impl true
  def store(
        endpoint,
        data,
        meta_data
      ) do
    filename = filename(meta_data)

    headers = [
      {"Content-Type", "text/plain"},
      {"x-ms-blob-type", "BlockBlob"}
    ]

    case url(endpoint, filename) do
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
  def filename(%{"identifier" => identifier}) do
    identifier
    |> Enum.map_join("_", fn [key, value] -> "#{key}-#{value}" end)
    |> then(&"#{&1}.json")
  end

  defp url(
         %{
           "account_name" => storage_account_name,
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
