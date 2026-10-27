defmodule Systems.Account.AuthCodeLimits do
  @moduledoc """
  Limits on sign-in codes on top of the checks each single code allows
  (`Systems.Account.AuthCodeModel`). They count per email address and per
  network address, in the database (`Rate.Public.increment_counter/2`), so all
  nodes share them and restarts don't reset them. Windows are fixed: a refused
  address or network is allowed again when the window ends.

  The default limits:
  - Requesting a code: 10 per email address per hour, 200 per network address
    per hour.
  - Checking a code: 10 per email address per hour and 30 per day, 200 per
    network address per hour. Only checks of an active code count.
  - While an email address can't check codes, it can't request new ones either.

  An IPv6 client counts by its /64 network, which one connection usually owns
  as a whole. The network address limits leave room for many people behind
  one address, such as a university network or a mobile carrier.

  The `AUTH_CODE_LIMITS` environment variable replaces the default limits of
  the action and count it lists (`overrides!/1`).
  """

  import Frameworks.Utility.ConfigHelpers

  alias Systems.Rate

  @windows %{minute: 60, hour: 60 * 60, day: 24 * 60 * 60}

  # {action, counted by, limit, window}
  @default_limits [
    {:request, :email, 10, :hour},
    {:request, :network, 200, :hour},
    {:check, :email, 10, :hour},
    {:check, :email, 30, :day},
    {:check, :network, 200, :hour}
  ]

  @doc """
  Counts a code request for `email` (normalised) from `remote_ip`; false when
  a limit refuses it.
  """
  def allow_request?(email, remote_ip) when is_binary(email) and is_binary(remote_ip) do
    checks_allowed?(email) and allow?(:request, email, remote_ip)
  end

  @doc """
  Counts a check of a code for `email` (normalised) from `remote_ip`; false
  when a limit refuses it.
  """
  def allow_check?(email, remote_ip) when is_binary(email) and is_binary(remote_ip) do
    allow?(:check, email, remote_ip)
  end

  @doc """
  The limits in force: the defaults, of which the configured overrides
  (`config :core, :auth_code_limits, overrides: …`) replace those of each
  action and count they list.
  """
  def limits do
    overrides = Core.Env.get(:auth_code_limits, []) |> Keyword.get(:overrides, [])
    overridden = MapSet.new(overrides, fn {action, by, _, _} -> {action, by} end)

    Enum.reject(@default_limits, fn {action, by, _, _} ->
      MapSet.member?(overridden, {action, by})
    end) ++ overrides
  end

  @doc """
  Parses the decoded JSON of `AUTH_CODE_LIMITS`, a list of limits such as
  `{"action": "check", "by": "email", "limit": 20, "window": "hour"}`:
  `action` is `request` or `check`, `by` is `email` or `network`, `window` is
  `minute`, `hour` or `day`. Raises on an invalid entry.
  """
  def overrides!(limits) when is_list(limits) do
    Enum.map(limits, fn limit ->
      {
        get!(:atom, limit, :action, [:request, :check]),
        get!(:atom, limit, :by, [:email, :network]),
        get!(:integer, limit, :limit),
        get!(:atom, limit, :window, Map.keys(@windows))
      }
    end)
  end

  defp checks_allowed?(email) do
    limits()
    |> Enum.filter(&match?({:check, :email, _, _}, &1))
    |> Enum.all?(fn {:check, :email, limit, window} ->
      Rate.Public.counter(key(:check, :email, email, nil), @windows[window]) < limit
    end)
  end

  defp allow?(action, email, remote_ip) do
    limits()
    |> Enum.filter(&match?({^action, _, _, _}, &1))
    |> Enum.all?(fn {^action, by, limit, window} ->
      Rate.Public.increment_counter(key(action, by, email, remote_ip), @windows[window]) <= limit
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
