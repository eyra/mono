defmodule Systems.DataDonation.AzureStorageBackend do
  @behaviour Systems.DataDonation.StorageBackend

  def store(
        %{"participant" => participant, "key" => donation_key},
        %{"storage_info" => %{"key" => root_key}},
        data
      ) do
    participant |> IO.inspect(label: "STORE")

    path = path(root_key, participant, donation_key) |> IO.inspect(label: "PATH")

    config = config() |> IO.inspect(label: "CONFIG")

    url = url(config, path) |> IO.inspect(label: "URL2")

    headers = [
      {"Content-Type", "text/plain"},
      {"x-ms-blob-type", "BlockBlob"}
    ]

    HTTPoison.put(url, data, headers)
    |> IO.inspect(label: "PUT")
    |> case do
      {:ok, %{status_code: 201}} ->
        :ok

      {_, %{status_code: status_code, body: body}} ->
        {:error, "status_code=#{status_code},message=#{body}"}

      {_, response} ->
        {:error, response}
    end
    |> IO.inspect(label: "RESULT")
  end

  def path(root_key, participant, donation_key) do
    "#{root_key}/#{participant}/#{donation_key}.json"
  end

  defp url(
         config,
         path
       ) do
    storage_account_name = Keyword.get(config, :storage_account_name) |> IO.inspect(label: "SAN")
    container = Keyword.get(config, :container) |> IO.inspect(label: "CON")
    sas_token = Keyword.get(config, :sas_token) |> IO.inspect(label: "SAS")

    "https://#{storage_account_name}.blob.core.windows.net/#{container}/#{path}#{sas_token}"
  end

  defp config() do
    Application.get_env(:core, :azure_storage_backend)
  end
end
