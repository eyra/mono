defmodule Systems.Rate.Public do
  use Core, :public

  defmodule RateLimitError do
    defexception [:message]
  end

  def request_permission(service, client_id, packet_size) when is_atom(service) do
    request_permission(service |> Atom.to_string(), client_id, packet_size)
  end

  def request_permission(service, client_id, packet_size)
      when is_binary(service) and is_binary(client_id) and is_integer(packet_size) do
    case Systems.Rate.Server.request_permission(service, client_id, packet_size) do
      {:denied, reason} -> raise RateLimitError, reason
      _ -> :granted
    end
  end
end
