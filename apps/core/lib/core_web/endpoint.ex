defmodule CoreWeb.Endpoint do
  alias CoreWeb.DependencyResolver

  def broadcast(conn, live_socket_id, message, opts) do
    endpoint(conn).broadcast(live_socket_id, message, opts)
  end

  defp endpoint(conn) do
    DependencyResolver.resolve(conn, :endpoint)
  end
end
