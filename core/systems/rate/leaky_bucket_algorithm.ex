defmodule Systems.Rate.LeakyBucketAlgorithm do
  @behaviour Systems.Rate.Algorithm

  alias Systems.Rate.Bucket
  alias Systems.Rate.LeakyBucketState, as: State
  alias Systems.Rate.BucketRef, as: Ref
  alias Systems.Rate.Quota, as: Quota

  @spec request_permission(map, :atom, String.t, integer) :: permission_result
  @impl true
  def request_permission(%State{quotas: quotas} = state, service, client_id, byte_count) do
    quotas = Enum.filter(quotas, & &1.service == service)
    do_request_permission(state, quotas, {service, client_id, byte_count})
  end

  @spec do_request_permission(State.t, :atom, String.t, request) :: permission_result
  defp do_request_permission(%State{} = state, quotas, request) do
    quotas |> Enum.reduce({:granted, state}, fn quota, acc ->
      do_request_permission(state, quota, request, acc)
    end)
  end

  @spec do_request_permission(Quota.t, request, permission_result) :: Ref.t
  defp do_request_permission(
    %Quota{rate_limit: rate_limit} = quota,
    {_, _, new_drops} = request,
    {:granted, %State{} = state}
  ) do
    now = DateTime.now!("Etc/UTC")
    key = bucket_key(quota, request)
    %{drops: drops} = bucket = get_or_create_bucket(state, quota, request, now, key)
    rate = rate(bucket, quota, request)

    do_request_permission(state, now, key, rate, rate_limit, drops + new_drops)
  end

  @spec do_request_permission(State.t, Quota.t, request, permission_result) :: Ref.t
  defp do_request_permission(_, _, _, acc), do: return acc


  @spec do_request_permission(State.t, DateTime.t, String.t, integer, integer, integer) :: Bucket.t
  defp do_request_permission(%State{} = state, now, key, rate, rate_limit, drops) do
    if rate < rate_limit do
      {
        :granted,
        State.update(state, key, Bucket.update(bucket, drops, now))
      }
    else
      {
        {
          :denied,
          "Rate limit exceeded: rate=#{rate} limit=#{rate_limit}"
        },
        state
      }
    end
  end

  @spec get_or_create_bucket(State.t, Quota.t, request, DateTime.t, String.t) :: Bucket.t
  defp get_or_create_bucket(%State{buckets: buckets}, %Quota{} = quota, request, now, key) do
    Enum.get(
      buckets,
      bucket_key(quota, request),
      initial_bucket(quota, now)
    )
  end

  @spec initial_bucket(Quota.t, DateTime.t) :: String.t
  defp initial_bucket(%Quota{window: window} = quota, %DateTime{} = now) do
    %Bucket{drops: 0, updated_at: DateTime.add(now, -1, window)}
  end

  @spec bucket_key(Quota.t, request) :: String.t
  defp bucket_key(%Quota{scope: :local, window: window, rate_limit: rate_limit}, {service, client_id, _}), do: "#{rate_limit}/#{window}@#{service}=>#{client_id}"

  @spec bucket_key(Quota.t, request) :: String.t
  defp bucket_key(%Quota{scope: :global, window: window, rate_limit: rate_limit}, {service, _, _}), do: "#{rate_limit}/#{window}@#{service}"

end
