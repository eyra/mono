defmodule Frameworks.UserCheck.HTTPClient do
  @moduledoc """
  Real HTTP client for the UserCheck email validation API.

  Calls `GET https://api.usercheck.com/email/{email}` with Bearer auth.
  Configured via application config:

      config :core, Frameworks.UserCheck,
        client: Frameworks.UserCheck.HTTPClient,
        api_key: "your_api_key",
        base_url: "https://api.usercheck.com",
        timeout: 2_000
  """

  @behaviour Frameworks.UserCheck.Client

  require Logger

  alias Frameworks.UserCheck.ResultModel

  @impl true
  def check_email(email) when is_binary(email) do
    url = "#{base_url()}/email/#{URI.encode(email)}"

    case :httpc.request(:get, {url, headers()}, http_options(), []) do
      {:ok, {{_, 200, _}, _headers, body}} ->
        {:ok, parse(body)}

      {:ok, {{_, status, _}, _headers, body}} ->
        Logger.warning("[UserCheck] HTTP #{status}: #{body}")
        {:error, {:http, status}}

      {:error, reason} ->
        Logger.warning("[UserCheck] Request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp parse(body) do
    body
    |> to_string()
    |> Jason.decode!()
    |> to_result()
  end

  defp to_result(json) do
    %ResultModel{
      disposable: Map.get(json, "disposable", false),
      mx: Map.get(json, "mx", true),
      blocklisted: Map.get(json, "blocklisted", false),
      role_account: Map.get(json, "role_account", false),
      public_domain: Map.get(json, "public_domain", false),
      alias: Map.get(json, "alias", false),
      spam: Map.get(json, "spam", false),
      did_you_mean: Map.get(json, "did_you_mean")
    }
  end

  defp headers do
    api_key = config(:api_key) || raise "USERCHECK_API_KEY not configured"

    [
      {~c"authorization", ~c"Bearer #{api_key}"},
      {~c"accept", ~c"application/json"}
    ]
  end

  defp http_options do
    [
      timeout: config(:timeout, 2_000),
      ssl: [
        verify: :verify_peer,
        cacerts: :public_key.cacerts_get(),
        depth: 3
      ]
    ]
  end

  defp base_url, do: config(:base_url, "https://api.usercheck.com")

  defp config(key, default \\ nil) do
    Application.get_env(:core, Frameworks.UserCheck, [])
    |> Keyword.get(key, default)
  end
end
