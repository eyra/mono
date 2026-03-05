defmodule Systems.Rate.Public do
  @moduledoc false
  use Core, :public

  defmodule RateLimitError do
    @moduledoc false
    defexception [:message]
  end

  def request_permission(service, client_id, packet_size) when is_atom(service) do
    service |> Atom.to_string() |> request_permission(client_id, packet_size)
  end

  def request_permission(service, client_id, packet_size)
      when is_binary(service) and is_binary(client_id) and is_integer(packet_size) do
    case Systems.Rate.Server.request_permission(service, client_id, packet_size) do
      {:denied, reason} -> raise RateLimitError, reason
      _ -> :granted
    end
  end
end
