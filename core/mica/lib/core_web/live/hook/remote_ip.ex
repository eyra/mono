defmodule CoreWeb.Live.Hook.RemoteIp do
  @moduledoc "A Live Hook that injects the remote_ip from a session variable."
  use Frameworks.Concept.LiveHook

  @impl true
  def mount(_live_view_module, _params, %{"remote_ip" => remote_ip}, socket) do
    {:cont, socket |> assign(remote_ip: remote_ip)}
  end
end

defmodule CoreWeb.Plug.RemoteIp do
  @moduledoc """
  Sets `conn.remote_ip` to the client's address and keeps it in the session
  as a string, for LiveViews (`CoreWeb.Live.Hook.RemoteIp`).

  A request from a loopback or private address came through a proxy (nginx
  on the host, or the platform's proxy); the client is then the last public
  address in `X-Forwarded-For`, which such a proxy sets or appends to. Other
  forwarding headers are ignored, as a proxy passes them on unchanged from the
  client. A request from a public address keeps that address.
  """
  import Plug.Conn, only: [put_session: 3]

  def init(options) do
    options
  end

  def call(%{remote_ip: peer} = conn, _opts) do
    remote_ip = client_ip(conn.req_headers, peer)

    %{conn | remote_ip: remote_ip}
    |> put_session(:remote_ip, to_string(:inet.ntoa(remote_ip)))
  end

  @doc """
  The client's address of a request with `headers` from `peer`, the address
  of the connection.
  """
  def client_ip(headers, peer) do
    if proxy?(peer) do
      RemoteIp.from(headers, headers: ["x-forwarded-for"]) || peer
    else
      peer
    end
  end

  defp proxy?({127, _, _, _}), do: true
  defp proxy?({10, _, _, _}), do: true
  defp proxy?({172, b, _, _}) when b in 16..31, do: true
  defp proxy?({192, 168, _, _}), do: true
  defp proxy?({0, 0, 0, 0, 0, 0, 0, 1}), do: true
  defp proxy?({a, _, _, _, _, _, _, _}) when a in 0xFC00..0xFDFF, do: true
  defp proxy?(_), do: false
end
