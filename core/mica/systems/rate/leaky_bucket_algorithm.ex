defmodule Systems.Rate.LeakyBucketAlgorithm do
  @behaviour Systems.Rate.Algorithm

  alias Systems.Rate.Private, as: Private
  alias Systems.Rate.Quota, as: Quota
  alias Systems.Rate.LeakyBucket, as: Bucket
  alias Systems.Rate.LeakyBucketState, as: State

  @impl true
  def request_permission(%State{quotas: quotas} = state, service, client_id, packet_size) do
    quotas = quotas |> Enum.filter(&(&1.service == service))
    do_request_permission(state, quotas, {service, client_id, packet_size})
  end

  defp do_request_permission(%State{} = state, quotas, request) do
    case Enum.reduce(quotas, {:granted, state}, fn quota, acc ->
           do_request_permission(quota, request, acc)
         end) do
      {:denied, reason} -> {{:denied, reason}, state}
      {:granted, new_state} -> {:granted, new_state}
    end
  end

  defp do_request_permission(
         %Quota{} = quota,
         request,
         {:granted, %State{} = state}
       ) do
    now = Private.datetime_now()
    key = bucket_key(quota, request)
    bucket = get_or_create_bucket(state, quota, request, now)
    new_drops = drops(quota, request)
    new_level = Bucket.level(bucket, now, new_drops)

    case new_level <= bucket.capacity do
      true ->
        {:granted, State.update(state, key, Bucket.update(bucket, new_level, now))}

      false ->
        {:denied, "Bucket overflow, skip packet: level=#{new_level} limit=#{bucket.capacity}"}
    end
  end

  defp do_request_permission(_, _, {:denied, reason}), do: {:denied, reason}

  defp get_or_create_bucket(%State{buckets: buckets}, %Quota{} = quota, request, now) do
    buckets
    |> Map.get(
      bucket_key(quota, request),
      initial_bucket(quota, now)
    )
  end

  defp initial_bucket(%Quota{limit: limit} = quota, %DateTime{} = now) do
    %Bucket{level: 0, capacity: limit, drop_rate: drop_rate(quota), updated_at: now}
  end

  defp bucket_key(
         %Quota{scope: :local, window: window, unit: unit, limit: limit},
         {service, client_id, _}
       ),
       do: "#{limit}:#{unit}/#{window}@#{service}=>#{client_id}"

  defp bucket_key(
         %Quota{scope: :global, window: window, unit: unit, limit: limit},
         {service, _, _}
       ),
       do: "#{limit}:#{unit}/#{window}@#{service}"

  defp drops(%Quota{unit: :byte}, {_, _, packet_size}), do: packet_size
  defp drops(%Quota{unit: :call}, _), do: 1

  defp drop_rate(%Quota{limit: limit, window: :second}), do: limit / 1000
  defp drop_rate(%Quota{limit: limit, window: :minute}), do: limit / (1000 * 60)
  defp drop_rate(%Quota{limit: limit, window: :hour}), do: limit / (1000 * 60 * 60)
  defp drop_rate(%Quota{limit: limit, window: :day}), do: limit / (1000 * 60 * 60 * 24)
end
