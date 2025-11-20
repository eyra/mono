defmodule CoreWeb.Plug.AcceptLanguage do
  @moduledoc """
  Persists the `accept-language` request header into the session.

  LiveViews can then read the raw header from the session to perform
  their own locale resolution logic (e.g. browser detection flow).
  """

  import Plug.Conn, only: [get_req_header: 2, put_session: 3]

  @session_key :accept_language

  def init(opts), do: opts

  def call(conn, _opts) do
    case conn |> get_req_header("accept-language") |> List.first() do
      nil -> conn
      "" -> conn
      header -> put_session(conn, @session_key, header)
    end
  end
end
