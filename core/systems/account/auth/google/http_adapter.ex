defmodule Systems.Account.Auth.Google.HTTPAdapter do
  @behaviour Assent.HTTPAdapter

  alias Assent.HTTPAdapter.HTTPResponse

  @impl true
  def request(method, url, body, headers, opts) do
    http_client = Keyword.get(opts || [], :http_client, HTTPoison)

    case http_client.request(method, url, body, headers) do
      {:ok, response} ->
        {:ok,
         %HTTPResponse{
           status: response.status_code,
           headers: response.headers,
           body: response.body
         }}

      {:error, error} ->
        {:error, error}
    end
  end
end
