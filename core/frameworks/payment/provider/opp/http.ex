defmodule Frameworks.Payment.Provider.OPP.HTTP do
  require Logger

  alias Frameworks.Payment.Error

  @spec get(String.t()) :: {:ok, map()} | {:error, Error.t()}
  def get(path) do
    request(:get, path)
  end

  @spec post(String.t(), map()) :: {:ok, map()} | {:error, Error.t()}
  def post(path, body) when is_map(body) do
    request(:post, path, body)
  end

  defp request(method, path, body \\ nil) do
    url = base_url() <> path
    headers = build_headers()

    Logger.debug("[OPP] #{method |> to_string() |> String.upcase()} #{url}")

    result =
      case method do
        :get -> HTTPoison.get(url, headers)
        :post -> HTTPoison.post(url, Jason.encode!(body), headers)
      end

    handle_response(result)
  end

  defp build_headers do
    [
      {"Authorization", "Bearer #{api_key()}"},
      {"Content-Type", "application/json"},
      {"Accept", "application/json"}
    ]
  end

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
    Application.fetch_env!(:core, :payment) |> Keyword.fetch!(:base_url)
  end

  defp api_key do
    Application.fetch_env!(:core, :payment) |> Keyword.fetch!(:api_key)
  end
end
