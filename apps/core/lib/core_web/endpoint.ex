defmodule CoreWeb.Endpoint do
  alias CoreWeb.Dependencies.Resolver

  def broadcast(conn, live_socket_id, message, opts) do
    endpoint(conn).broadcast(live_socket_id, message, opts)
  end

  defp endpoint(conn) do
    Resolver.resolve(conn, :endpoint)
  end
end
