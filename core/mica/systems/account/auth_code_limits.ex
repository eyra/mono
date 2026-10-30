defmodule Systems.Account.AuthCodeLimits do
  @moduledoc """
  Limits on sign-in codes on top of the checks each single code allows
  (`Systems.Account.AuthCodeModel`). They count per email address, per email
  address and network address together, and per network address, in the
  database (`Rate.Public.increment_counter/2`), so all nodes share them and
  restarts don't reset them. Windows are fixed: a refused address or network
  is allowed again when the window ends.

  The default limits:
  - Requesting a code: 10 per email address and network address per hour,
    50 per email address per day, 200 per network address per hour.
  - Checking a code: 10 per email address and network address per hour and
    30 per day, 100 per email address per day, 200 per network address per
    hour. Only checks of a code with attempts left count.
  - While an email address can't check codes from a network address, it can't
    request new ones from there either; at its daily total of checks, from
    nowhere.

  Counting an email address per network address means requests from one
  network address can't use up the limits of the same email address on
  another; the limits per email address alone bound the total across all
  network addresses.

  The totals per email address count last, after every other limit has
  passed: only requests that send a code and checks that compare a code count
  toward them, so events another limit refuses don't use them up.

  An IPv6 client counts by its /64 network, which one connection usually owns
  as a whole. The network address limits leave room for many people behind
  one address, such as a university network or a mobile carrier.

  The `AUTH_CODE_LIMITS` environment variable replaces the default limit of
  each action, count and window it lists (`overrides!/1`); the other limits
  keep their defaults. A window without a default adds a limit. A default
  limit can be raised but not removed.
  """

  import Frameworks.Utility.ConfigHelpers

  alias Systems.Rate

  @windows %{minute: 60, hour: 60 * 60, day: 24 * 60 * 60}

  # {action, counted by, limit, window}
  @default_limits [
    {:request, :email_network, 10, :hour},
    {:request, :email, 50, :day},
    {:request, :network, 200, :hour},
    {:check, :email_network, 10, :hour},
    {:check, :email_network, 30, :day},
    {:check, :email, 100, :day},
    {:check, :network, 200, :hour}
  ]

  @doc """
  Counts a code request for `email` (normalised) from `remote_ip` against the
  limits per network address (`email_network` and `network`); false when one
  refuses it. The totals per email address count separately, with
  `count_request?/1`, once every other limit has passed.
  """
  def allow_request?(email, remote_ip) when is_binary(email) and is_binary(remote_ip) do
    checks_allowed?(email, remote_ip) and allow?(per_network(:request), email, remote_ip)
  end

  @doc """
  Counts a code request for `email` (normalised) against the totals per email
  address; false when one refuses it. Call it last, right before the code is
  sent, so only requests that send a code count.
  """
  def count_request?(email) when is_binary(email) do
    allow?(totals(:request), email, nil)
  end

  @doc """
  Counts a check of a code for `email` (normalised) from `remote_ip` against
  the limits per network address; false when one refuses it. The totals per
  email address count separately, with `count_check?/1`.
  """
  def allow_check?(email, remote_ip) when is_binary(email) and is_binary(remote_ip) do
    allow?(per_network(:check), email, remote_ip)
  end

  @doc """
  Counts a check of a code for `email` (normalised) against the totals per
  email address; false when one refuses it. When the check then turns out not
  to reach the code, because the code has no attempts left, `uncount_check/1`
  takes it back, so the totals only count checks that compare a code.
  """
  def count_check?(email) when is_binary(email) do
    allow?(totals(:check), email, nil)
  end

  @doc """
  Takes back a check that `count_check?/1` counted.
  """
  def uncount_check(email) when is_binary(email) do
    Enum.each(totals(:check), fn {:check, :email, _limit, window} ->
      Rate.Public.decrement_counter(key(:check, :email, email, nil), @windows[window])
    end)
  end

  @doc """
  The limits in force: the defaults, of which the configured overrides
  (`config :mica, :auth_code_limits, overrides: …`) replace the one with the
  same action, count and window.
  """
  def limits do
    overrides = Mica.Env.get(:auth_code_limits, []) |> Keyword.get(:overrides, [])
    overridden = MapSet.new(overrides, fn {action, by, _, window} -> {action, by, window} end)

    Enum.reject(@default_limits, fn {action, by, _, window} ->
      MapSet.member?(overridden, {action, by, window})
    end) ++ overrides
  end

  @doc """
  Parses the decoded JSON of `AUTH_CODE_LIMITS`, a list of limits such as
  `{"action": "check", "by": "email", "limit": 20, "window": "hour"}`:
  `action` is `request` or `check`, `by` is `email`, `email_network` or
  `network`, `window` is `minute`, `hour` or `day`, and `limit` is a positive
  integer. Raises on an invalid entry, and on an action, count and window
  listed more than once.
  """
  def overrides!(limits) when is_list(limits) do
    limits
    |> Enum.map(fn limit ->
      {
        get!(:atom, limit, :action, [:request, :check]),
        get!(:atom, limit, :by, [:email, :email_network, :network]),
        positive_integer!(limit),
        get!(:atom, limit, :window, Map.keys(@windows))
      }
    end)
    |> unique!()
  end

  defp unique!(overrides) do
    overrides
    |> Enum.frequencies_by(fn {action, by, _, window} -> {action, by, window} end)
    |> Enum.find(fn {_, count} -> count > 1 end)
    |> case do
      nil -> overrides
      {limit, _} -> raise("A limit is listed more than once: #{inspect(limit)}")
    end
  end

  defp positive_integer!(%{"limit" => limit}) when is_integer(limit) and limit > 0, do: limit

  defp positive_integer!(entry),
    do: raise("The limit must be a positive integer: #{inspect(entry)}")

  defp checks_allowed?(email, remote_ip) do
    limits()
    |> Enum.filter(&match?({:check, by, _, _} when by in [:email, :email_network], &1))
    |> Enum.all?(fn {:check, by, limit, window} ->
      Rate.Public.counter(key(:check, by, email, remote_ip), @windows[window]) < limit
    end)
  end

  defp per_network(action) do
    Enum.filter(limits(), &match?({^action, by, _, _} when by in [:email_network, :network], &1))
  end

  defp totals(action), do: Enum.filter(limits(), &match?({^action, :email, _, _}, &1))

  # Each counter counts and compares in one statement, so concurrent events
  # can't pass a limit together.
  defp allow?(limits, email, remote_ip) do
    Enum.all?(limits, fn {action, by, limit, window} ->
      Rate.Public.increment_counter(key(action, by, email, remote_ip), @windows[window]) <= limit
    end)
  end

  defp key(action, :email, email, _remote_ip), do: "auth_code_#{action}:email:#{email}"

  defp key(action, :email_network, email, remote_ip),
    do: "auth_code_#{action}:email_network:#{email}:#{network(remote_ip)}"

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
