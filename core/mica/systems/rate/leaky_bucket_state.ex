defmodule Systems.Rate.LeakyBucketState do
  require Logger

  alias Systems.Rate.Private, as: Private
  alias Systems.Rate.Quota, as: Quota
  alias Systems.Rate.LeakyBucket, as: Bucket

  @type t :: %__MODULE__{
          prune_interval: integer,
          quotas: [Quota.t()],
          buckets: %{String.t() => Bucket.t()}
        }

  @enforce_keys [:prune_interval, :quotas, :buckets]
  defstruct [:prune_interval, :quotas, :buckets]

  def init(prune_interval, quotas) do
    %__MODULE__{prune_interval: prune_interval, quotas: quotas, buckets: %{}}
  end

  def update(%__MODULE__{buckets: buckets} = state, key, %Bucket{} = bucket) do
    Map.put(state, :buckets, Map.put(buckets, key, bucket))
  end

  def prune(%__MODULE__{buckets: buckets} = state) do
    now = Private.datetime_now()

    new_buckets =
      Enum.reduce(buckets, %{}, fn {key, bucket}, acc ->
        if Bucket.level(bucket, now) > 0 do
          Map.put(acc, key, bucket)
        else
          acc
        end
      end)

    count_before = Enum.count(buckets)
    count_after = Enum.count(new_buckets)
    Logger.info("[#{__MODULE__}] Pruned #{count_before - count_after} of #{count_before} buckets")

    state |> Map.put(:buckets, new_buckets)
  end
end
