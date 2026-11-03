defmodule Systems.Affiliate.Private do
  require Logger

  def merge(_redirect_url, _user_info, extra_query \\ %{})
  def merge(nil, _user_info, _extra_query), do: {:error, :redirect_url_missing}
  def merge("", _user_info, _extra_query), do: {:error, :redirect_url_missing}
  def merge(redirect_url, %{info: info}, extra_query), do: merge(redirect_url, info, extra_query)

  def merge(redirect_url, info, extra_query)
      when is_binary(redirect_url) and (is_binary(info) or is_nil(info)) do
    url =
      redirect_url
      |> URI.parse()
      |> merge_query(to_map(info))
      |> merge_query(extra_query)
      |> URI.to_string()

    {:ok, url}
  end

  def merge_query(%URI{query: nil} = url, %{} = query) do
    merge_query(%URI{url | query: ""}, query)
  end

  def merge_query(%URI{query: old_query} = url, %{} = query) do
    %URI{
      url
      | query:
          old_query
          |> URI.decode_query()
          |> Map.merge(query)
          |> URI.encode_query()
    }
  end

  def to_map(nil), do: %{}

  def to_map(json_string) when is_binary(json_string) do
    Jason.decode!(json_string)
  end

  def callback(%{affiliate: affiliate}, user_info, event),
    do: callback(affiliate, user_info, event)

  def callback(%{callback_url: nil}, _user_info, _event), do: {:error, :callback_url_missing}
  def callback(%{callback_url: ""}, _user_info, _event), do: {:error, :callback_url_missing}

  def callback(%{callback_url: callback_url}, user_info, event) do
    case merge(callback_url, user_info, event) do
      {:ok, url} -> callback(url)
      error -> error
    end
  end

  def callback(url) when is_binary(url) do
    case request_status(url) do
      {:ok, status} ->
        {:ok, status}

      error ->
        Logger.error("Error calling callback url: #{url}, error: #{inspect(error)}")
        error
    end
  end

  # The researcher's server answers inside the participant's process. Only the
  # status is used, and hackney 4 would read the whole body before returning,
  # so the response is taken asynchronously and stopped after its status line.
  # The deadline covers the whole call, connecting included.
  @callback_limits [connect_timeout: 5_000, deadline: 10_000]

  # `:hackney.close/1` waits without limit for a connection that is still
  # reading headers; this stops it or kills it.
  @stop_timeout 100

  defp request_status(url) do
    limits = callback_limits()
    deadline = Keyword.fetch!(limits, :deadline)
    connect_timeout = min(Keyword.fetch!(limits, :connect_timeout), deadline)
    deadline_at = System.monotonic_time(:millisecond) + deadline

    options = [
      async: :once,
      pool: false,
      connect_timeout: connect_timeout,
      recv_timeout: deadline
    ]

    connections_before = own_connections()

    case :hackney.request(:get, url, [], "", options) do
      {:ok, ref} ->
        result = await_status(ref, max(deadline_at - System.monotonic_time(:millisecond), 0))
        stop_connection(ref)
        flush_responses(ref)
        result

      error ->
        # A request that fails after connecting leaves its connection running.
        Enum.each(own_connections() -- connections_before, &stop_connection/1)
        error
    end
  end

  # A hackney connection monitors the process that owns it.
  defp own_connections do
    {:monitored_by, monitors} = Process.info(self(), :monitored_by)
    Enum.filter(monitors, &hackney_connection?/1)
  end

  defp hackney_connection?(pid) when is_pid(pid) do
    case Process.info(pid, :dictionary) do
      {:dictionary, dictionary} -> match?({:hackney_conn, _, _}, dictionary[:"$initial_call"])
      nil -> false
    end
  end

  defp hackney_connection?(_port_or_resource), do: false

  # `hackney_conn.stop/2` can raise, e.g. OTP's `:timeout_value` when the
  # connection exits right at the timeout; hackney's own `stop_conn/1` catches
  # every class too.
  defp stop_connection(connection) do
    :hackney_conn.stop(connection, @stop_timeout)
  catch
    _kind, _reason -> Process.exit(connection, :kill)
  end

  defp await_status(ref, timeout) do
    receive do
      {:hackney_response, ^ref, {:status, status, _reason}} -> {:ok, status}
      {:hackney_response, ^ref, {:error, reason}} -> {:error, reason}
    after
      timeout -> {:error, :deadline_exceeded}
    end
  end

  defp flush_responses(ref) do
    receive do
      {:hackney_response, ^ref, _} -> flush_responses(ref)
    after
      0 -> :ok
    end
  end

  defp callback_limits do
    Keyword.merge(@callback_limits, Mica.Env.get(:affiliate_callback, []))
  end

  def redirect_url(%{redirect_url: nil}, _user), do: {:error, :redirect_url_missing}
  def redirect_url(%{redirect_url: ""}, _user), do: {:error, :redirect_url_missing}

  def redirect_url(%{redirect_url: redirect_url}, user_info) do
    merge(redirect_url, user_info)
  end
end
