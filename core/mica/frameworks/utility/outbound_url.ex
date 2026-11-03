defmodule Frameworks.Utility.OutboundUrl do
  @moduledoc """
  Requests to URLs that users enter, such as an affiliate's callback URL.

  Only `https` URLs whose host resolves to public addresses are allowed: no
  loopback, private, link-local, CGNAT, multicast, reserved or cloud metadata
  addresses, IPv4 or IPv6. `request/5` resolves the host again and connects to
  the address it checked, so a name can't resolve to a public address when the
  URL is saved and to a private one when it is requested. TLS still verifies
  the certificate against the host name. Redirects are never followed.
  """

  import Bitwise

  @type reason :: :invalid_url | :scheme_not_allowed | :host_not_found | :address_not_allowed

  @resolve_timeout 5_000

  # IPv4 ranges that aren't public: RFC 6890 and the CGNAT range of RFC 6598.
  # 169.254.0.0/16 holds most cloud metadata services, 100.64.0.0/10 Alibaba's
  # and 192.0.0.0/24 Oracle's.
  @blocked_ipv4 [
    {{0, 0, 0, 0}, 8},
    {{10, 0, 0, 0}, 8},
    {{100, 64, 0, 0}, 10},
    {{127, 0, 0, 0}, 8},
    {{169, 254, 0, 0}, 16},
    {{172, 16, 0, 0}, 12},
    {{192, 0, 0, 0}, 24},
    {{192, 0, 2, 0}, 24},
    {{192, 88, 99, 0}, 24},
    {{192, 168, 0, 0}, 16},
    {{198, 18, 0, 0}, 15},
    {{198, 51, 100, 0}, 24},
    {{203, 0, 113, 0}, 24},
    {{224, 0, 0, 0}, 4},
    {{240, 0, 0, 0}, 4}
  ]

  # IPv6 ranges inside global unicast (2000::/3) that aren't public: IETF
  # protocol assignments (Teredo among them), documentation, and 6to4, whose
  # IPv4 address is checked instead. Everything outside 2000::/3 is refused.
  @global_unicast_ipv6 {{0x2000, 0, 0, 0, 0, 0, 0, 0}, 3}
  @blocked_ipv6 [
    {{0x2001, 0, 0, 0, 0, 0, 0, 0}, 23},
    {{0x2001, 0x0DB8, 0, 0, 0, 0, 0, 0}, 32},
    {{0x3FFF, 0, 0, 0, 0, 0, 0, 0}, 20}
  ]

  @doc """
  Checks that `url` is an `https` URL whose host resolves to public addresses
  only. A host that doesn't resolve gives `{:error, :host_not_found}`.
  `opts[:resolver]` replaces the DNS lookup, for tests.
  """
  @spec check(String.t(), keyword()) :: {:ok, URI.t(), :inet.ip_address()} | {:error, reason}
  def check(url, opts \\ []) when is_binary(url) do
    resolver = Keyword.get(opts, :resolver, &resolve/1)

    with {:ok, %URI{host: host} = uri} <- parse(url),
         {:ok, addresses} <- resolver.(host),
         :ok <- all_public(addresses) do
      {:ok, uri, preferred(addresses)}
    end
  end

  @doc """
  `:hackney.request/5` to `url` after `check/2`, connected to the checked
  address and without following redirects.
  """
  def request(method, url, headers, body, options) do
    {resolver, options} = Keyword.pop(options, :resolver, &resolve/1)

    case check(url, resolver: resolver) do
      {:ok, uri, address} ->
        {pinned_url, headers, options} = pin(uri, address, headers, options)
        :hackney.request(method, pinned_url, headers, body, options)

      error ->
        error
    end
  end

  @doc """
  True for an address on the public internet. IPv4-mapped, NAT64 and 6to4
  IPv6 addresses are judged by the IPv4 address they carry.
  """
  @spec public_address?(:inet.ip_address()) :: boolean()
  def public_address?({_, _, _, _} = address) do
    not Enum.any?(@blocked_ipv4, &in_range?(address, &1))
  end

  def public_address?({0, 0, 0, 0, 0, 0xFFFF, high, low}), do: public_address?(ipv4(high, low))

  def public_address?({0x64, 0xFF9B, 0, 0, 0, 0, high, low}),
    do: public_address?(ipv4(high, low))

  def public_address?({0x2002, high, low, _, _, _, _, _}), do: public_address?(ipv4(high, low))

  def public_address?({_, _, _, _, _, _, _, _} = address) do
    in_range?(address, @global_unicast_ipv6) and
      not Enum.any?(@blocked_ipv6, &in_range?(address, &1))
  end

  defp parse(url) do
    case URI.new(url) do
      {:ok, %URI{scheme: "https", host: host} = uri} when is_binary(host) and host != "" ->
        {:ok, uri}

      {:ok, %URI{scheme: scheme}} when scheme != "https" ->
        {:error, :scheme_not_allowed}

      _ ->
        {:error, :invalid_url}
    end
  end

  defp resolve(host) do
    host = String.to_charlist(host)

    addresses =
      for family <- [:inet, :inet6],
          {:ok, addresses} <- [:inet.getaddrs(host, family, @resolve_timeout)],
          address <- addresses,
          do: address

    case Enum.uniq(addresses) do
      [] -> {:error, :host_not_found}
      addresses -> {:ok, addresses}
    end
  end

  # Every address must be public: hackney would otherwise be free to pick
  # a private one of a name that also has a public one.
  defp all_public([_ | _] = addresses) do
    if Enum.all?(addresses, &public_address?/1),
      do: :ok,
      else: {:error, :address_not_allowed}
  end

  defp all_public([]), do: {:error, :host_not_found}

  defp preferred(addresses) do
    Enum.find(addresses, List.first(addresses), &match?({_, _, _, _}, &1))
  end

  defp pin(%URI{host: host} = uri, address, headers, options) do
    options =
      Keyword.merge(options, follow_redirect: false, protocols: [:http1])

    if ip_literal?(host) do
      {URI.to_string(uri), headers, options}
    else
      pinned_url = URI.to_string(%URI{uri | host: :inet.ntoa(address) |> to_string()})
      headers = [{"host", host_header(uri)} | headers]
      sni = {:server_name_indication, host |> String.trim_trailing(".") |> to_charlist()}
      options = Keyword.update(options, :ssl_options, [sni], &[sni | &1])
      {pinned_url, headers, options}
    end
  end

  defp host_header(%URI{host: host, port: 443}), do: host
  defp host_header(%URI{host: host, port: port}), do: "#{host}:#{port}"

  defp ip_literal?(host), do: match?({:ok, _}, :inet.parse_strict_address(to_charlist(host)))

  defp ipv4(high, low), do: {high >>> 8, high &&& 0xFF, low >>> 8, low &&& 0xFF}

  defp in_range?(address, {base, bits}) when tuple_size(address) == tuple_size(base) do
    size = if tuple_size(address) == 4, do: 32, else: 128
    shift = size - bits
    to_integer(address) >>> shift == to_integer(base) >>> shift
  end

  defp in_range?(_address, _range), do: false

  defp to_integer({_, _, _, _} = address) do
    address |> Tuple.to_list() |> Enum.reduce(0, &(&2 <<< 8 ||| &1))
  end

  defp to_integer({_, _, _, _, _, _, _, _} = address) do
    address |> Tuple.to_list() |> Enum.reduce(0, &(&2 <<< 16 ||| &1))
  end
end
