defmodule Mica.ExAws.Hackney do
  @moduledoc """
  The `ExAws.Request.HttpClient` for hackney 4.

  ex_aws 2.7.0's own `ExAws.Request.Hackney` has no clause for the
  `{:ok, status, headers}` that hackney 4 returns for a HEAD request, so every
  `ExAws.S3.head_object/2` raises, and with it `ExAws.S3.download_file/4`.
  This client handles that reply as ex_aws 2.6 did. It reads the same options:

      config :ex_aws, :hackney_opts, recv_timeout: 30_000
  """

  @behaviour ExAws.Request.HttpClient

  @default_opts [recv_timeout: 30_000]

  @impl true
  def request(method, url, body \\ "", headers \\ [], http_opts \\ []) do
    opts = http_opts ++ Application.get_env(:ex_aws, :hackney_opts, @default_opts)

    method
    |> :hackney.request(url, headers, body, opts)
    |> to_response()
  end

  defp to_response({:ok, status, headers}), do: {:ok, %{status_code: status, headers: headers}}

  defp to_response({:ok, status, headers, body}),
    do: {:ok, %{status_code: status, headers: headers, body: body}}

  defp to_response({:error, reason}), do: {:error, %{reason: reason}}
end
