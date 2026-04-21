defmodule Systems.Payment.Provider.OPP.HTTP do
  require Logger

  alias Systems.Payment.Error

  @timeout 10_000
  @recv_timeout 30_000

  @spec get(String.t()) :: {:ok, map()} | {:error, Error.t()}
  def get(path) do
    request(:get, path)
  end

  @spec post(String.t(), map(), list()) :: {:ok, map()} | {:error, Error.t()}
  def post(path, body, extra_headers \\ []) when is_map(body) do
    request(:post, path, body, extra_headers)
  end

  defp request(method, path, body \\ nil, extra_headers \\ []) do
    url = base_url() <> path
    headers = build_headers() ++ extra_headers
    options = [timeout: @timeout, recv_timeout: @recv_timeout]
    request_id = Ecto.UUID.generate()
    start_time = System.monotonic_time(:millisecond)

    Logger.info("[OPP] Request",
      request_id: request_id,
      method: method |> to_string() |> String.upcase(),
      path: path
    )

    result =
      case method do
        :get -> HTTPoison.get(url, headers, options)
        :post -> HTTPoison.post(url, Jason.encode!(body), headers, options)
      end

    duration = System.monotonic_time(:millisecond) - start_time

    Logger.info("[OPP] Response",
      request_id: request_id,
      duration_ms: duration,
      status: extract_status(result)
    )

    handle_response(result)
  end

  defp build_headers do
    [
      {"Authorization", "Bearer #{api_key()}"},
      {"Content-Type", "application/json"},
      {"Accept", "application/json"}
    ]
  end

  defp extract_status({:ok, %HTTPoison.Response{status_code: status}}), do: status
  defp extract_status({:error, %HTTPoison.Error{reason: reason}}), do: inspect(reason)

  defp handle_response({:ok, %HTTPoison.Response{status_code: status, body: body}})
       when status in 200..299 do
    case Jason.decode(body) do
      {:ok, parsed} ->
        {:ok, parsed}

      {:error, _} ->
        {:error, %Error{code: :invalid_response, message: "Invalid JSON response"}}
    end
  end

  defp handle_response({:ok, %HTTPoison.Response{status_code: status, body: body}}) do
    details =
      case Jason.decode(body) do
        {:ok, parsed} -> parsed
        {:error, _} -> %{"raw" => body}
      end

    {:error,
     %Error{
       code: :api_error,
       message: "OPP API returned #{status}",
       details: %{status: status, body: details}
     }}
  end

  defp handle_response({:error, %HTTPoison.Error{reason: reason}}) do
    {:error,
     %Error{
       code: :connection_error,
       message: "Failed to connect to OPP: #{inspect(reason)}"
     }}
  end

  defp base_url do
    Application.fetch_env!(:core, Systems.Payment.Provider.OPP) |> Keyword.fetch!(:base_url)
  end

  defp api_key do
    Application.fetch_env!(:core, Systems.Payment.Provider.OPP) |> Keyword.fetch!(:api_key)
  end
end
