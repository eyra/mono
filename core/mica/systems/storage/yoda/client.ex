defmodule Systems.Storage.Yoda.Client do
  alias Frameworks.Utility.HTTPClient
  require Logger

  # issue with HTTPPoison not supporting HTTP method :mkcol
  @dialyzer {:nowarn_function, create_folder: 3}

  def upload_file(username, password, file_url, body) do
    headers = headers(username, password)
    http_request(:put, file_url, body, headers)
  end

  def create_folder(username, password, folder_url) do
    headers = headers(username, password)
    http_request(:mkcol, folder_url, "", headers)
  end

  def connected?(username, password, folder_url) do
    has_resource?(username, password, folder_url)
  end

  def has_resource?(username, password, resource_url) do
    headers = headers(username, password)

    case http_request(:head, resource_url, "", headers) do
      {:ok, %HTTPoison.Response{status_code: 200}} ->
        {:ok, true}

      {:ok, %HTTPoison.Response{}} ->
        {:ok, false}

      {:error, error} ->
        {:error, "Request failed: #{inspect(error)}"}
    end
  end

  defp headers(username, password) do
    [
      {"Content-type", "application/json"},
      {"Authorization", "Basic " <> Base.encode64("#{username}:#{password}")}
    ]
  end

  defp http_request(method, url, body, headers, options \\ []) do
    case HTTPClient.request(method, url, body, headers, options) do
      {:error, error} ->
        Logger.error("Yoda request failed: #{inspect(error)}")
        {:error, error}

      {:ok, response} ->
        {:ok, response}
    end
  end
end
