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

    with {:ok, ref} <- :hackney.request(:get, url, [], "", options) do
      result = await_status(ref, max(deadline_at - System.monotonic_time(:millisecond), 0))
      :hackney_conn.stop(ref, @stop_timeout)
      flush_responses(ref)
      result
    end
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
