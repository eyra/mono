defmodule Systems.Storage.Yoda.Client do
  alias Frameworks.Utility.OutboundUrl
  require Logger

  def upload_file(username, password, file_url, body) do
    headers = headers(username, password)

    case http_request(:put, file_url, body, headers) do
      {:ok, status} when status in 200..299 ->
        {:ok, status}

      {:ok, status} ->
        {:error, {:http_status, status}}

      {:error, error} ->
        {:error, error}
    end
  end

  def connected?(username, password, folder_url) do
    has_resource?(username, password, folder_url)
  end

  def has_resource?(username, password, resource_url) do
    headers = headers(username, password)

    case http_request(:head, resource_url, "", headers) do
      {:ok, 200} ->
        {:ok, true}

      {:ok, _status} ->
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

  defp http_request(method, url, body, headers) do
    case OutboundUrl.request(method, url, headers, body, []) do
      {:ok, status, _headers} ->
        {:ok, status}

      {:ok, status, _headers, _body} ->
        {:ok, status}

      {:error, error} ->
        Logger.error("Yoda request failed: #{inspect(error)}")
        {:error, error}
    end
  end
end
