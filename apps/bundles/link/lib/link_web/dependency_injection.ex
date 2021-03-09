defmodule LinkWeb.DependencyInjection do
  @behaviour Plug

  alias Plug.Conn

  @impl true
  def init(opts) do
    opts
  end

  @impl true
  def call(conn, _opts) do
    Conn.fetch_session(conn)
    |> Conn.put_session(:path_provider, LinkWeb.PathProvider)
  end
end
