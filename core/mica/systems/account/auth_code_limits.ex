defmodule Systems.Account.AuthCodeLimits do
  @moduledoc """
  Limits on sign-in codes on top of the checks each single code allows
  (`Systems.Account.AuthCodeModel`). They count per email address and per
  network address, in the database (`Rate.Public.increment_counter/2`), so all
  nodes share them and restarts don't reset them. Windows are fixed: a refused
  address or network is allowed again when the window ends.

  - Requesting a code: 10 per email address per hour, 200 per network address
    per hour.
  - Checking a code: 10 per email address per hour and 30 per day, 200 per
    network address per hour. Only checks of an active code count.
  - While an email address can't check codes, it can't request new ones either.

  An IPv6 client counts by its /64 network, which one connection usually owns
  as a whole. The network address limits leave room for many people behind
  one address, such as a university network or a mobile carrier.
  """

  alias Systems.Rate

  @hour 60 * 60
  @day 24 * @hour

  # {counted by, limit, window in seconds}
  @request_limits [
    {:email, 10, @hour},
    {:network, 200, @hour}
  ]

  @check_limits [
    {:email, 10, @hour},
    {:email, 30, @day},
    {:network, 200, @hour}
  ]

  @doc """
  Counts a code request for `email` (normalised) from `remote_ip`; false when
  a limit refuses it.
  """
  def allow_request?(email, remote_ip) when is_binary(email) and is_binary(remote_ip) do
    checks_allowed?(email) and allow?(:request, @request_limits, email, remote_ip)
  end

  @doc """
  Counts a check of a code for `email` (normalised) from `remote_ip`; false
  when a limit refuses it.
  """
  def allow_check?(email, remote_ip) when is_binary(email) and is_binary(remote_ip) do
    allow?(:check, @check_limits, email, remote_ip)
  end

  defp checks_allowed?(email) do
    @check_limits
    |> Enum.filter(fn {by, _, _} -> by == :email end)
    |> Enum.all?(fn {by, limit, window} ->
      Rate.Public.counter(key(:check, by, email, nil), window) < limit
    end)
  end

  defp allow?(action, limits, email, remote_ip) do
    Enum.all?(limits, fn {by, limit, window} ->
      Rate.Public.increment_counter(key(action, by, email, remote_ip), window) <= limit
    end)
  end

  defp key(action, :email, email, _remote_ip), do: "auth_code_#{action}:email:#{email}"

  defp key(action, :network, _email, remote_ip),
    do: "auth_code_#{action}:network:#{network(remote_ip)}"

  @doc """
  The network address `remote_ip` counts by: an IPv4 address as is, an IPv6
  address by its /64 prefix.
  """
  def network(remote_ip) when is_binary(remote_ip) do
    case :inet.parse_strict_address(String.to_charlist(remote_ip)) do
      {:ok, {0, 0, 0, 0, 0, 0xFFFF, _, _} = ip} ->
        ip |> :inet.ipv4_mapped_ipv6_address() |> ntoa()

      {:ok, {a, b, c, d, _, _, _, _}} ->
        ntoa({a, b, c, d, 0, 0, 0, 0}) <> "/64"

      {:ok, ip} ->
        ntoa(ip)

      {:error, _} ->
        remote_ip
    end
  end

  defp ntoa(ip), do: ip |> :inet.ntoa() |> to_string()
end
