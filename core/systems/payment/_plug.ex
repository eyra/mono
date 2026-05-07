defmodule Systems.Payment.Plug do
  @moduledoc """
  Caches the raw request body for webhook signature verification.

  Used as a custom body_reader for Plug.Parsers. The raw body is stored
  in conn.assigns[:raw_body] so it can be used for HMAC verification.
  """

  def cache_body_reader(%{request_path: "/api/payment/" <> _} = conn, opts) do
    {:ok, body, conn} = Plug.Conn.read_body(conn, opts)
    conn = Plug.Conn.assign(conn, :raw_body, body)
    {:ok, body, conn}
  end

  def cache_body_reader(conn, opts) do
    Plug.Conn.read_body(conn, opts)
  end
end
