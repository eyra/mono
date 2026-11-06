defmodule Next.Systems.Account.NativeSigninGuard do
  @moduledoc """
  Admits only same-origin JSON requests from the Next native apps to the
  native sign-in calls.

  The calls carry and set the session cookie, so they need CSRF protection.
  They are made with `fetch` from a hidden WKWebView that has a document on
  Mica's origin, so instead of a CSRF token they require:

    * an `Origin` header naming the host the request was sent to, and no
      cross-site `Sec-Fetch-Site`;
    * `Content-Type: application/json`, which no HTML form can send and which
      makes any cross-origin `fetch` preflight, which Mica never grants.

  The `NextApp/<version> iOS|Android` user agent keeps the calls to the apps;
  browsers sign in through the LiveView pages. It is not a security control.
  """

  @behaviour Plug

  import Plug.Conn

  alias Next.Systems.Account.NativeApp

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    cond do
      not same_origin?(conn) -> reject(conn, :forbidden, "forbidden")
      not json?(conn) -> reject(conn, :unsupported_media_type, "unsupported_media_type")
      not NativeApp.request?(conn) -> reject(conn, :forbidden, "unsupported_client")
      true -> conn
    end
  end

  defp same_origin?(%{host: host} = conn) do
    origin_host?(get_req_header(conn, "origin"), host) and
      get_req_header(conn, "sec-fetch-site") in [[], ["same-origin"]]
  end

  defp origin_host?([origin], host), do: URI.parse(origin).host == host
  defp origin_host?(_origins, _host), do: false

  defp json?(conn) do
    case get_req_header(conn, "content-type") do
      [content_type] ->
        match?({:ok, "application", "json", _}, Plug.Conn.Utils.content_type(content_type))

      _ ->
        false
    end
  end

  defp reject(conn, status, error) do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> put_status(status)
    |> Phoenix.Controller.json(%{error: error})
    |> halt()
  end
end
