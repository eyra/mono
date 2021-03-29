defmodule CoreWeb.EndpointProxy do
  alias CoreWeb.Dependencies.Resolver

  def broadcast(conn, live_socket_id, message, opts) do
    endpoint(conn).broadcast(live_socket_id, message, opts)
  end

  def subscribe(conn, live_socket_id) do
    endpoint(conn).subscribe(live_socket_id)
  end

  defp endpoint(conn) do
    [:endpoint, :phoenix_endpoint]
    |> Enum.find_value(:error, &Resolver.resolve(conn, &1))
  end
end
