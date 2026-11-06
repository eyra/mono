defmodule MicaWeb.Live.Hook.RemoteIp do
  @moduledoc "A Live Hook that injects the remote_ip from a session variable."
  use Frameworks.Concept.LiveHook

  @impl true
  def mount(_live_view_module, _params, %{"remote_ip" => remote_ip}, socket) do
    {:cont, socket |> assign(remote_ip: remote_ip)}
  end
end

defmodule MicaWeb.Plug.RemoteIp do
  @moduledoc """
  Sets `conn.remote_ip` to the client's address, keeps it in the session as a
  string for LiveViews (`MicaWeb.Live.Hook.RemoteIp`), and adds it to the
  Logger metadata as `remote_ip`.

  A request from a trusted proxy (nginx on the host, or the platform's proxy)
  comes from the last address in `X-Forwarded-For` that isn't a trusted proxy,
  as such a proxy sets or appends to that header. Other forwarding headers are
  ignored, as a proxy passes them on unchanged from the client. A request from
  any other address keeps that address.

  The trusted proxies are the loopback and private ranges, unless the
  `TRUSTED_PROXIES` environment variable lists others (`trusted_proxies!/1`).
  """
  import Bitwise
  import Plug.Conn, only: [put_session: 3]

  require Logger

  @default_trusted_proxies ~w[127.0.0.0/8 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 ::1/128 fc00::/7]

  def init(options) do
    options
  end

  def call(%{remote_ip: peer} = conn, _opts) do
    remote_ip = client_ip(conn.req_headers, peer)
    Logger.metadata(remote_ip: ntoa(remote_ip))

    %{conn | remote_ip: remote_ip}
    |> put_session(:remote_ip, ntoa(remote_ip))
  end

  @doc """
  The client's address of a request with `headers` from `peer`, the address
  of the connection.
  """
  def client_ip(headers, peer) do
    proxies = trusted_proxies()

    if Enum.any?(proxies, &contains?(parse_cidr!(&1), peer)) do
      RemoteIp.from(headers, headers: ["x-forwarded-for"], proxies: proxies) || peer
    else
      peer
    end
  end

  defp trusted_proxies do
    Mica.Env.get(__MODULE__, [])
    |> Keyword.get(:trusted_proxies, @default_trusted_proxies)
  end

  @doc """
  Checks the trusted proxies of `TRUSTED_PROXIES`: addresses or CIDR ranges,
  IPv4 or IPv6. Raises an `ArgumentError` on an entry that is neither, and on
  an empty list: behind a proxy, that would count every client as the proxy.
  """
  def trusted_proxies!([]),
    do: raise(ArgumentError, "TRUSTED_PROXIES lists no proxies; unset it for the default")

  def trusted_proxies!(proxies) when is_list(proxies) do
    Enum.each(proxies, &parse_cidr!/1)
    proxies
  end

  defp parse_cidr!(cidr) do
    with [address | prefix] <- String.split(cidr, "/", parts: 2),
         {:ok, ip} <- :inet.parse_strict_address(String.to_charlist(address)),
         size = address_bits(ip),
         {:ok, prefix} <- prefix_length(prefix, size) do
      {size, prefix, ip_bits(ip) >>> (size - prefix)}
    else
      _ -> raise ArgumentError, "not an IP address or CIDR range: #{inspect(cidr)}"
    end
  end

  defp prefix_length([], size), do: {:ok, size}

  defp prefix_length([prefix], size) do
    case Integer.parse(prefix) do
      {length, ""} when length >= 0 and length <= size -> {:ok, length}
      _ -> :error
    end
  end

  defp contains?({size, prefix, net}, ip) do
    address_bits(ip) == size and ip_bits(ip) >>> (size - prefix) == net
  end

  defp address_bits(ip) when tuple_size(ip) == 4, do: 32
  defp address_bits(ip) when tuple_size(ip) == 8, do: 128

  defp ip_bits({_, _, _, _} = ip), do: to_bits(ip, 8)
  defp ip_bits({_, _, _, _, _, _, _, _} = ip), do: to_bits(ip, 16)

  defp to_bits(ip, width) do
    ip |> Tuple.to_list() |> Enum.reduce(0, fn part, acc -> acc <<< width ||| part end)
  end

  defp ntoa(ip), do: ip |> :inet.ntoa() |> to_string()
end
